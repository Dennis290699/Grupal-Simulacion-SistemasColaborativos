<template>
  <div class="dashboard">
    <header class="header">
      <div class="header-left">
        <span class="header-tag">BDI · GAMA Platform</span>
        <h1 class="header-title">WannaCry Network Simulation</h1>
      </div>
      <div class="header-stats">
        <div class="stat" :class="{ danger: stats.infectados > 0 }">
          <span class="stat-value">{{ stats.infectados }}</span>
          <span class="stat-label">Infectados</span>
        </div>
        <div class="stat">
          <span class="stat-value">{{ stats.sanos }}</span>
          <span class="stat-label">Sanos</span>
        </div>
        <div class="stat warn">
          <span class="stat-value">{{ stats.aislados }}</span>
          <span class="stat-label">Aislados</span>
        </div>
        <div class="stat">
          <span class="stat-value">{{ stats.ciclo }}</span>
          <span class="stat-label">Ciclo</span>
        </div>
        <div class="pulse-dot" :class="pollingActive ? 'active' : 'inactive'"></div>
      </div>
    </header>

    <section class="map-section">
      <div class="section-label">Red · Topología en vivo</div>
      <CytoscapeMap ref="cyCompRef" :base="BASE" @init="onCyInit" @ready="onCyReady" />
      <div class="legend">
        <span class="leg-item"><span class="dot" style="background:#22c55e"></span>Sano</span>
        <span class="leg-item"><span class="dot" style="background:#ef4444"></span>Infectado</span>
        <span class="leg-item"><span class="dot"
            style="background:#1e293b;border:2px solid #475569"></span>Aislado</span>
        <span class="leg-item">🖥️ PC</span>
        <span class="leg-item">🛡️ Firewall</span>
        <span class="leg-item">🔀 Switch</span>
        <span class="leg-item">☁️ Internet</span>
        <span class="leg-item">🗄️ Server</span>
      </div>
    </section>

    <ChartsGrid ref="chartsRef" @mounted="onChartsMounted">
      <template #events>
        <tr v-for="(ev, i) in eventosRecientes" :key="i" :class="rowClass(ev.evento)">
          <td>{{ ev.ciclo }}</td>
          <td>{{ ev.nodo }}</td>
          <td><span class="badge" :class="badgeClass(ev.evento)">{{ ev.evento }}</span></td>
          <td>{{ ev.desde }}</td>
          <td>{{ ev.probabilidad && ev.probabilidad !== '-' ? parseFloat(ev.probabilidad).toFixed(3) : '-' }}</td>
        </tr>
      </template>
    </ChartsGrid>
  </div>
</template>

<script setup>
import { ref, onUnmounted, computed, nextTick } from 'vue'
import * as echarts from 'echarts'
import CytoscapeMap from './components/CytoscapeMap.vue'
import ChartsGrid from './components/ChartsGrid.vue'
import { fetchCSV, cleanRow } from './composables/usePolling'


const BASE = '/results'

const cyCompRef = ref(null)  // Referencia a componente CytoscapeMap
const chartsRef = ref(null)   // Referencia a componente ChartsGrid

// Instancias reales de librerías (no reactivas, persistentes)
let cyComp = null             // Instancia de Cytoscape
let ecInfectados = null       // Instancia ECharts para infectados
let ecPatch = null            // Instancia ECharts para patch level
let ecIntenciones = null      // Instancia ECharts para intenciones BDI
let pollTimer = null          // ID del setInterval de encuesta
let pollingStarted = false    // Bandera para evitar múltiples inicios

const pollingActive = ref(false)
const eventos = ref([])
const nodoEstado = ref({})

const stats = computed(() => {
  const vals = Object.values(nodoEstado.value)
  const infectados = vals.filter(n => n.infected && !n.is_internet).length
  const aislados = vals.filter(n => n.isolated).length
  const sanos = vals.filter(n => !n.infected && !n.is_internet && !n.isolated).length
  const ultimo = eventos.value.length ? eventos.value[eventos.value.length - 1].ciclo : 0
  return { infectados, aislados, sanos, ciclo: ultimo }
})

const eventosRecientes = computed(() => [...eventos.value].reverse().slice(0, 50))

// ── CYTOSCAPE callbacks ───────────────────────────────────
function onCyInit(initialEstado) {
  nodoEstado.value = initialEstado
}

function onCyReady() {
  cyComp = cyCompRef?.value
}

function updateCyNode(nombre, infected, isolated) {
  if (!cyComp) return
  cyComp.updateNode(nombre, infected, isolated)
}

// ════════════════════════════════════════════════════════════════
// CICLO DE VIDA: INICIALIZACIÓN DE GRÁFICOS
// ════════════════════════════════════════════════════════════════
async function onChartsMounted() {
  await waitForChartRefs()  // Polling: espera a que refs tengan .value
  initCharts()              // Inicializa 3 instancias ECharts
  startPolling()            // Comienza encuesta periódica c/2s
}


function waitForChartRefs(maxTries = 30) {
  return new Promise((resolve) => {
    let tries = 0
    function check() {
      // Intenta acceder a los elementos DOM de las 3 refs
      const infectEl = chartsRef.value?.infectados
      const patchEl = chartsRef.value?.patch
      const intencionesEl = chartsRef.value?.intenciones

      // Si todos tienen .value (elemento DOM), éxito
      if (infectEl && patchEl && intencionesEl) {
        resolve()
        return
      }

      // Aún no listos, reintentar en próximo frame
      tries++
      if (tries >= maxTries) {
        console.error('⚠️ ChartsGrid refs no resueltos tras', maxTries, 'frames (~0.5s)')
        resolve() // Resolver igual para no colgar la app
        return
      }

      // Polling con requestAnimationFrame = más eficiente que setTimeout
      requestAnimationFrame(check)
    }
    requestAnimationFrame(check)
  })
}

// ════════════════════════════════════════════════════════════════
// INSTANCIACIÓN DE GRÁFICOS ECHARTS
// ════════════════════════════════════════════════════════════════
function initCharts() {
  // Guard: no reiniciar si ya existen instancias
  if (ecInfectados || ecPatch || ecIntenciones) return

  // Obtener referencias DOM desde ChartsGrid expuestas
  const infectEl = chartsRef.value?.infectados
  const patchEl = chartsRef.value?.patch
  const intencionesEl = chartsRef.value?.intenciones

  // Guard: si alguno falta, no proceder
  if (!infectEl || !patchEl || !intencionesEl) {
    console.warn('⚠️ ChartsGrid refs no disponibles en initCharts()')
    return
  }

  // Inicializar 3 instancias ECharts independientes con tema oscuro
  ecInfectados = echarts.init(infectEl, 'dark')
  ecPatch = echarts.init(patchEl, 'dark')
  ecIntenciones = echarts.init(intencionesEl, 'dark')

  const baseOpt = {
    backgroundColor: 'transparent',
    grid: { left: 44, right: 16, top: 16, bottom: 36 },
    xAxis: { type: 'category', data: [], axisLabel: { color: '#94a3b8', fontSize: 10 } },
    yAxis: { type: 'value', axisLabel: { color: '#94a3b8', fontSize: 10 }, splitLine: { lineStyle: { color: '#1e293b' } } },
    tooltip: { trigger: 'axis' },
  }

  ecInfectados.setOption({
    ...baseOpt,
    series: [{ name: 'Infectados', type: 'line', data: [], smooth: true, itemStyle: { color: '#ef4444' }, areaStyle: { color: 'rgba(239,68,68,0.15)' } }],
  })

  ecPatch.setOption({
    ...baseOpt,
    series: [{ name: 'Patch avg', type: 'line', data: [], smooth: true, itemStyle: { color: '#22c55e' }, areaStyle: { color: 'rgba(34,197,94,0.15)' } }],
  })

  ecIntenciones.setOption({
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'shadow' },
      formatter: function (params) {
        const map = { spread: 'Propagar', patch: 'Parchar', isolated: 'Aislar', normal: 'Normal' }
        let res = `<div style="font-family: monospace;">Ciclo: ${params[0].name}</div>`
        params.forEach(item => {
          if (item.value > 0) {
            const label = map[item.seriesName] || item.seriesName
            res += `<div style="font-family: monospace;">${item.marker} ${label}: <b>${item.value}</b></div>`
          }
        })
        return res
      }
    },
    legend: {
      data: ['spread', 'patch', 'isolated', 'normal'],
      textStyle: { color: '#94a3b8', fontSize: 10 },
      top: 4,
      formatter: function (name) {
        const map = { spread: 'Propagar', patch: 'Parchar', isolated: 'Aislar', normal: 'Normal' }
        return map[name] || name
      }
    },
    grid: { left: 44, right: 16, top: 36, bottom: 36 },
    xAxis: { type: 'category', data: [], axisLabel: { color: '#94a3b8', fontSize: 10 } },
    yAxis: { type: 'value', axisLabel: { color: '#94a3b8', fontSize: 10 }, splitLine: { lineStyle: { color: '#1e293b' } } },
    series: [
      { name: 'spread', type: 'bar', stack: 'total', data: [], itemStyle: { color: '#ef4444' } },
      { name: 'patch', type: 'bar', stack: 'total', data: [], itemStyle: { color: '#22c55e' } },
      { name: 'isolated', type: 'bar', stack: 'total', data: [], itemStyle: { color: '#475569' } },
      { name: 'normal', type: 'bar', stack: 'total', data: [], itemStyle: { color: '#1e293b' } },
    ],
  })
}

// ════════════════════════════════════════════════════════════════
// ENCUESTA PERIÓDICA DE LOGS (POLLING)
// ════════════════════════════════════════════════════════════════

let lastRowCount = 0  // Controla qué filas son "nuevas" desde último poll

function startPolling() {
  if (pollingStarted) return  // Guard: evita múltiples inicios
  
  pollingStarted = true
  pollingActive.value = true  // Activa indicador visual (pulse-dot)
  pollTimer = setInterval(pollCSV, 2000)  // Encuesta cada 2 segundos
  pollCSV()  // Carga inicial inmediata
}

onUnmounted(() => clearInterval(pollTimer))

async function pollCSV() {
  try {
    // Descargar CSV de log_eventos
    const rawRows = await fetchCSV(`${BASE}/log_eventos.csv`)
    const rows = rawRows.map(cleanRow)  // Normalizar espacios

    // Si no hay nuevas filas desde último poll, salir
    if (rows.length <= lastRowCount) return

    // Extraer solo las filas nuevas
    const nuevas = rows.slice(lastRowCount)
    lastRowCount = rows.length

    // Procesar cada evento nuevo (actualiza nodoEstado, cytoscape)
    nuevas.forEach(procesarEvento)
    
    // Forzar reactividad sobre el array completo
    eventos.value = [...rows]
    
    // Actualizar datos en los 3 gráficos (infectados, patch, intenciones)
    updateCharts(rows)

    // Redimensionar Cytoscape si la red cambió
    if (cyComp) cyComp.resizeFit()
  } catch (e) {
    console.warn('⚠️ Poll error:', e.message)
  }
}

/**
 * Procesa un evento individual del log.
 */
function procesarEvento(ev) {
  const nodo = ev.nodo
  const evento = ev.evento
  const desde = ev.desde

  // Guard: evento inválido
  if (!nodo || nodo === '-') return

  // ─── INFECCIÓN: marca nodo como infectado ────────────────────
  if (evento === 'Infeccion_Exitosa') {
    if (nodoEstado.value[nodo]) {
      nodoEstado.value[nodo].infected = true
      nodoEstado.value[nodo].isolated = false
    }
    updateCyNode(nodo, true, false)  // Actualiza visualización

    // Si hay origen de ataque, dibujar arco rojo
    if (desde && desde !== '-') {
      cyComp?.markAttackEdge(desde, nodo)
    }
  }

  // ─── AISLAMIENTO: marca nodo como aislado ────────────────────
  if (evento === 'AISLADO' || evento === 'AISLADO_EMERGENCIA' || evento === 'Aislamiento_Contencion') {
    if (nodoEstado.value[nodo]) {
      nodoEstado.value[nodo].infected = true
      nodoEstado.value[nodo].isolated = true
    }
    updateCyNode(nodo, true, true)  // Muestra ícono de aislado
  }

  // ─── PARCHEO: marca nodo como sano ───────────────────────────
  if (evento === 'PARCHEO') {
    if (nodoEstado.value[nodo]) {
      nodoEstado.value[nodo].infected = false
      nodoEstado.value[nodo].isolated = false
    }
    updateCyNode(nodo, false, false)  // Restaura ícono de sano
  }
}

/**
 * Actualiza series de datos en los 3 gráficos ECharts.
 */
function updateCharts(rows) {
  // Guard: instancias aún no inicializadas
  if (!ecInfectados || !ecPatch || !ecIntenciones) return

  // Extraer lista única de ciclos en orden
  const ciclosSet = [...new Set(rows.map(r => r.ciclo))].sort((a, b) => parseInt(a) - parseInt(b))

  // ─── SERIE 1: Infectados por ciclo ────────────────────────────
  const infectSerie = ciclosSet.map(c => {
    const filasC = rows.filter(r => r.ciclo === c && r.infectados_total && r.infectados_total !== '-')
    if (!filasC.length) return null
    return parseInt(filasC[filasC.length - 1].infectados_total)
  })

  // ─── SERIE 2: Patch level promedio por ciclo ──────────────────
  const patchRows = rows.filter(r => r.evento === 'PARCHEO')
  const patchCiclos = [...new Set(patchRows.map(r => r.ciclo))].sort((a, b) => parseInt(a) - parseInt(b))
  const patchSerie = patchCiclos.map(c => {
    const vals = patchRows.filter(r => r.ciclo === c).map(r => parseInt(r.patch_lv)).filter(v => !isNaN(v))
    return vals.length ? Math.round(vals.reduce((a, b) => a + b, 0) / vals.length) : 0
  })

  // ─── SERIE 3: Intenciones BDI por ciclo (barras apiladas) ──────
  const spreadSerie = ciclosSet.map(c => rows.filter(r => r.ciclo === c && r.intencion === 'spread').length)
  const patchISerie = ciclosSet.map(c => rows.filter(r => r.ciclo === c && r.intencion === 'patch').length)
  const isolateSerie = ciclosSet.map(c => rows.filter(r => r.ciclo === c && (r.intencion === 'isolated' || r.intencion === 'isolate')).length)
  const normalSerie = ciclosSet.map(c => rows.filter(r => r.ciclo === c && r.intencion === 'normal').length)

  // Actualizar gráficos con nuevas series
  ecInfectados.setOption({ xAxis: { data: ciclosSet }, series: [{ data: infectSerie }] })
  ecPatch.setOption({ xAxis: { data: patchCiclos }, series: [{ data: patchSerie }] })
  ecIntenciones.setOption({
    xAxis: { data: ciclosSet },
    series: [
      { name: 'spread', data: spreadSerie },
      { name: 'patch', data: patchISerie },
      { name: 'isolated', data: isolateSerie },
      { name: 'normal', data: normalSerie },
    ],
  })
}

function rowClass(evento) {
  if (evento === 'Infeccion_Exitosa') return 'row-infected'
  if (evento?.includes('AISLADO')) return 'row-isolated'
  if (evento === 'ALERTA_CRITICA') return 'row-alert'
  if (evento === 'PARCHEO') return 'row-patch'
  return ''
}

function badgeClass(evento) {
  if (evento === 'Infeccion_Exitosa') return 'badge-red'
  if (evento?.includes('AISLADO')) return 'badge-dark'
  if (evento === 'ALERTA_CRITICA') return 'badge-orange'
  if (evento === 'PARCHEO') return 'badge-green'
  return 'badge-gray'
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600&family=Inter:wght@400;500;600&display=swap');

* { box-sizing: border-box; margin: 0; padding: 0; }

.dashboard {
  min-height: 100vh;
  background: #0a0f1e;
  color: #e2e8f0;
  font-family: 'Inter', sans-serif;
  display: flex;
  flex-direction: column;
}

.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 24px;
  background: #0d1526;
  border-bottom: 1px solid #1e293b;
}

.header-tag {
  font-family: 'JetBrains Mono', monospace;
  font-size: 10px;
  color: #f97316;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  display: block;
  margin-bottom: 2px;
}

.header-title { font-size: 18px; font-weight: 600; letter-spacing: -0.02em; color: #f1f5f9; }
.header-stats { display: flex; align-items: center; gap: 24px; }
.stat { text-align: center; }
.stat-value { display: block; font-family: 'JetBrains Mono', monospace; font-size: 22px; font-weight: 600; color: #f1f5f9; line-height: 1; }
.stat-label { display: block; font-size: 10px; color: #64748b; text-transform: uppercase; letter-spacing: 0.08em; margin-top: 2px; }
.stat.danger .stat-value { color: #ef4444; }
.stat.warn .stat-value { color: #f97316; }

.pulse-dot { width: 10px; height: 10px; border-radius: 50%; }
.pulse-dot.active { background: #22c55e; box-shadow: 0 0 0 3px rgba(34, 197, 94, 0.3); animation: pulse 1.5s infinite; }
.pulse-dot.inactive { background: #334155; }
@keyframes pulse { 0%, 100% { box-shadow: 0 0 0 3px rgba(34, 197, 94, 0.3) } 50% { box-shadow: 0 0 0 6px rgba(34, 197, 94, 0.1) } }

.map-section { padding: 16px 24px 8px; }
.section-label { font-family: 'JetBrains Mono', monospace; font-size: 10px; color: #475569; text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 8px; }

.legend { display: flex; gap: 16px; margin-top: 8px; flex-wrap: wrap; }
.leg-item { display: flex; align-items: center; gap: 6px; font-size: 11px; color: #64748b; }
.dot { width: 10px; height: 10px; border-radius: 50%; display: inline-block; }

.chart-label { font-family: 'JetBrains Mono', monospace; font-size: 10px; color: #475569; text-transform: uppercase; letter-spacing: 0.08em; }

.row-infected td { background: rgba(239, 68, 68, 0.07); }
.row-isolated td { background: rgba(30, 41, 59, 0.5); }
.row-alert td { background: rgba(249, 115, 22, 0.1); }
.row-patch td { background: rgba(34, 197, 94, 0.06); }

.badge { display: inline-block; padding: 1px 6px; border-radius: 3px; font-size: 9px; font-weight: 600; letter-spacing: 0.05em; }
.badge-red { background: rgba(239, 68, 68, 0.2); color: #f87171; }
.badge-dark { background: rgba(15, 23, 42, 0.8); color: #94a3b8; }
.badge-orange { background: rgba(249, 115, 22, 0.2); color: #fb923c; }
.badge-green { background: rgba(34, 197, 94, 0.2); color: #4ade80; }
.badge-gray { background: rgba(51, 65, 85, 0.5); color: #64748b; }
</style>
