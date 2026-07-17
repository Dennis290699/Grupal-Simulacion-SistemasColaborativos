<template>
  <div class="stats-page">
    <header class="stats-header">
      <div>
        <span class="stats-tag">BDI · GAMA Platform</span>
        <h1 class="stats-title">Estadísticas de Simulaciones</h1>
        <p class="stats-subtitle">
          {{ allRows.length }} simulaciones registradas en el histórico
        </p>
      </div>
      <button class="refresh-button" type="button" @click="cargarDatos" :disabled="loading">
        {{ loading ? 'Cargando...' : 'Actualizar' }}
      </button>
    </header>

    <div v-if="error" class="stats-state error">{{ error }}</div>

    <template v-else>
      <!-- ───────────────────────────── Controles de filtro ───────────────────────────── -->
      <section class="controls-card">
        <div class="control-group">
          <label>Agrupar por</label>
          <div class="segmented">
            <button
              type="button"
              :class="{ active: agruparPor === 'nivel_firewall' }"
              @click="agruparPor = 'nivel_firewall'"
            >Nivel Firewall</button>
            <button
              type="button"
              :class="{ active: agruparPor === 'nivel_contencion' }"
              @click="agruparPor = 'nivel_contencion'"
            >Nivel Contención</button>
          </div>
        </div>

        <div class="control-group">
          <label>Valor a analizar</label>
          <select v-model="valorSeleccionado" class="select-input">
            <option value="todos">Todos (comparar todos los valores)</option>
            <option v-for="v in valoresDisponibles" :key="v" :value="v">{{ v }}%</option>
          </select>
        </div>
      </section>

      <!-- ───────────────────────────── Resumen general comparado ───────────────────────────── -->
      <section class="chart-card">
        <div class="section-label">
          Comparación entre valores de {{ agruparPor === 'nivel_firewall' ? 'Nivel Firewall' : 'Nivel Contención' }}
        </div>
        <div ref="chartResumenEl" class="chart-box"></div>
      </section>

      <!-- ───────────────────────────── Detalle del valor seleccionado ───────────────────────────── -->
      <section class="detail-grid">
        <div class="stat-card">
          <span class="stat-card-value">{{ statsSeleccion.total }}</span>
          <span class="stat-card-label">Simulaciones</span>
        </div>
        <div class="stat-card success">
          <span class="stat-card-value">{{ formatPct(statsSeleccion.tasaContencion) }}</span>
          <span class="stat-card-label">Tasa de contención total</span>
        </div>
        <div class="stat-card">
          <span class="stat-card-value">{{ formatHoras(statsSeleccion.avgTiempoContencion) }}</span>
          <span class="stat-card-label">Tiempo promedio de contención</span>
        </div>
        <div class="stat-card danger">
          <span class="stat-card-value">{{ formatNum(statsSeleccion.avgInfectados) }}</span>
          <span class="stat-card-label">Promedio infectados</span>
        </div>
        <div class="stat-card">
          <span class="stat-card-value">{{ formatNum(statsSeleccion.avgAsalvo) }}</span>
          <span class="stat-card-label">Promedio a salvo</span>
        </div>
        <div class="stat-card">
          <span class="stat-card-value">{{ formatNum(statsSeleccion.avgParche) }}%</span>
          <span class="stat-card-label">Promedio parche máximo</span>
        </div>
      </section>

      <section class="charts-row">
        <div class="chart-card half">
          <div class="section-label">Contenidas vs No contenidas</div>
          <div ref="chartPieEl" class="chart-box"></div>
        </div>
        <div class="chart-card half">
          <div class="section-label">Infectados vs A salvo (promedio)</div>
          <div ref="chartInfSalEl" class="chart-box"></div>
        </div>
      </section>

      <!-- ───────────────────────────── Tabla detalle ───────────────────────────── -->
      <section class="table-card">
        <div class="section-label">
          Detalle · {{ filasFiltradas.length }} simulación(es)
          {{ valorSeleccionado === 'todos' ? '' : `con ${agruparPor === 'nivel_firewall' ? 'firewall' : 'contención'} = ${valorSeleccionado}%` }}
        </div>
        <div class="table-frame">
          <table class="stats-table">
            <thead>
              <tr>
                <th>#</th>
                <th>Escenario</th>
                <th>Parche Máx.</th>
                <th>Tiempo Contención</th>
                <th>Infectados</th>
                <th>A salvo</th>
                <th>Firewall</th>
                <th>Contención</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(row, i) in filasFiltradas" :key="i">
                <td>{{ i + 1 }}</td>
                <td><strong style="color:#f97316">{{ row.escenario }}</strong></td>
                <td>{{ row.nivel_max_parche }}%</td>
                <td style="font-family: monospace;">{{ tiempoTexto(row) }}</td>
                <td>{{ row.numero_infectados }}</td>
                <td>{{ row.numero_asalvo }}</td>
                <td>{{ row.nivel_firewall }}%</td>
                <td>{{ row.nivel_contencion }}%</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, nextTick } from 'vue'
import * as echarts from 'echarts'
import { fetchCSV, cleanRow } from '../components/usePolling'

const BASE = '/results'

const allRows = ref([])
const loading = ref(false)
const error = ref('')

const agruparPor = ref('nivel_firewall') // 'nivel_firewall' | 'nivel_contencion'
const valorSeleccionado = ref('todos')

const chartResumenEl = ref(null)
const chartPieEl = ref(null)
const chartInfSalEl = ref(null)
let ecResumen = null
let ecPie = null
let ecInfSal = null

function parseNumber(value) {
  if (value === '' || value === null || value === undefined) return null
  const n = Number(value)
  return Number.isNaN(n) ? null : n
}

function formatNum(n) {
  if (n === null || n === undefined) return '-'
  return Math.round(n)
}

function formatPct(n) {
  if (n === null || n === undefined) return '-'
  return `${Math.round(n)}%`
}

function formatHoras(ciclos) {
  if (ciclos === null || ciclos === undefined) return '-'
  const dias = Math.floor(ciclos / 24)
  const horas = Math.round(ciclos % 24)
  if (dias > 0) return `${dias}d ${horas}h`
  return `${horas}h`
}

function tiempoTexto(row) {
  const inicio = parseNumber(row.ciclo_inicio_infeccion)
  const fin = parseNumber(row.ciclo_fin_contencion)
  const cicloFinal = parseNumber(row.ciclo_final)
  const aSalvo = parseNumber(row.numero_asalvo)

  if (inicio === null || inicio < 0) return '-'
  
  // Si no queda nadie a salvo, la simulación falló / colapsó. No hubo contención.
  // También si explícitamente se guardó un valor negativo de no contención (-1)
  if (aSalvo === 0 || fin === null || fin < 0) {
    const delta = (cicloFinal ?? 0) - inicio
    return `> ${delta}h (sin contener)`
  }

  // Si queda población a salvo y hay ciclo de fin válido
  return `${fin - inicio}h`
}

/**
 * Carga el histórico completo de simulaciones desde log_informes.csv
 */
async function cargarDatos() {
  loading.value = true
  error.value = ''
  try {
    const t = Date.now()
    const rawRows = await fetchCSV(`${BASE}/log_informes.csv?t=${t}`)
    allRows.value = rawRows.map(cleanRow)
    await nextTick()
    renderCharts()
  } catch (e) {
    error.value = `No se pudo cargar el histórico: ${e.message}`
  } finally {
    loading.value = false
  }
}

// Valores únicos disponibles para el campo de agrupamiento activo
const valoresDisponibles = computed(() => {
  const vals = [...new Set(allRows.value.map(r => r[agruparPor.value]).filter(v => v !== null && v !== undefined && v !== ''))]
  return vals.sort((a, b) => Number(a) - Number(b))
})

// Al cambiar el campo de agrupamiento, resetear la selección a "todos"
watch(agruparPor, () => {
  valorSeleccionado.value = 'todos'
})

// Filas que corresponden al valor actualmente seleccionado (o todas)
const filasFiltradas = computed(() => {
  if (valorSeleccionado.value === 'todos') return allRows.value
  return allRows.value.filter(r => r[agruparPor.value] === valorSeleccionado.value)
})

/**
 * Calcula estadísticas agregadas (tasa de contención, promedios, etc.)
 * para un conjunto de filas.
 */
function statsFor(rows) {
  const total = rows.length
  const contenidasRows = rows.filter(r => {
    const inicio = parseNumber(r.ciclo_inicio_infeccion)
    const fin = parseNumber(r.ciclo_fin_contencion)
    const aSalvo = parseNumber(r.numero_asalvo)
    
    // Una simulación se considera exitosamente contenida si:
    // 1. Hubo un inicio de infección válido.
    // 2. Terminó en un ciclo de contención válido (>= 0).
    // 3. Sobrevivió al menos un nodo sano (a salvo > 0).
    return inicio !== null && inicio >= 0 && fin !== null && fin >= 0 && aSalvo !== null && aSalvo > 0
  })
  
  const tiempos = contenidasRows.map(r => parseNumber(r.ciclo_fin_contencion) - parseNumber(r.ciclo_inicio_infeccion))
  const avg = arr => (arr.length ? arr.reduce((a, b) => a + b, 0) / arr.length : null)

  return {
    total,
    contenidas: contenidasRows.length,
    tasaContencion: total ? (contenidasRows.length / total) * 100 : null,
    avgTiempoContencion: avg(tiempos),
    avgInfectados: avg(rows.map(r => parseNumber(r.numero_infectados)).filter(v => v !== null)),
    avgAsalvo: avg(rows.map(r => parseNumber(r.numero_asalvo)).filter(v => v !== null)),
    avgParche: avg(rows.map(r => parseNumber(r.nivel_max_parche)).filter(v => v !== null)),
  }
}
const statsSeleccion = computed(() => statsFor(filasFiltradas.value))

// Resumen de estadísticas por CADA valor disponible (para el gráfico comparativo)
const resumenPorValor = computed(() => {
  return valoresDisponibles.value.map(v => {
    const rows = allRows.value.filter(r => r[agruparPor.value] === v)
    return { valor: v, ...statsFor(rows) }
  })
})

function renderCharts() {
  if (!chartResumenEl.value || !chartPieEl.value || !chartInfSalEl.value) return

  if (!ecResumen) ecResumen = echarts.init(chartResumenEl.value, 'dark')
  if (!ecPie) ecPie = echarts.init(chartPieEl.value, 'dark')
  if (!ecInfSal) ecInfSal = echarts.init(chartInfSalEl.value, 'dark')

  const labels = resumenPorValor.value.map(r => `${r.valor}%`)

  // ── Gráfico comparativo: tasa de contención y tiempo promedio por valor ──
  ecResumen.setOption({
    backgroundColor: 'transparent',
    tooltip: { trigger: 'axis' },
    legend: { data: ['Tasa de contención (%)', 'Tiempo promedio (h)'], textStyle: { color: '#94a3b8', fontSize: 10 }, top: 4 },
    grid: { left: 50, right: 50, top: 40, bottom: 36 },
    xAxis: { type: 'category', data: labels, axisLabel: { color: '#94a3b8', fontSize: 10 } },
    yAxis: [
      { type: 'value', name: '%', axisLabel: { color: '#94a3b8', fontSize: 10 }, splitLine: { lineStyle: { color: '#1e293b' } } },
      { type: 'value', name: 'horas', axisLabel: { color: '#94a3b8', fontSize: 10 }, splitLine: { show: false } },
    ],
    series: [
      {
        name: 'Tasa de contención (%)',
        type: 'bar',
        data: resumenPorValor.value.map(r => r.tasaContencion !== null ? Math.round(r.tasaContencion) : 0),
        itemStyle: { color: '#22c55e' },
        yAxisIndex: 0,
      },
      {
        name: 'Tiempo promedio (h)',
        type: 'line',
        smooth: true,
        data: resumenPorValor.value.map(r => r.avgTiempoContencion !== null ? Math.round(r.avgTiempoContencion) : null),
        itemStyle: { color: '#f97316' },
        yAxisIndex: 1,
      },
    ],
  })

  // ── Gráfico de pastel: contenidas vs no contenidas (para la selección actual) ──
  const s = statsSeleccion.value
  ecPie.setOption({
    backgroundColor: 'transparent',
    tooltip: { trigger: 'item' },
    legend: { bottom: 0, textStyle: { color: '#94a3b8', fontSize: 10 } },
    series: [
      {
        type: 'pie',
        radius: ['45%', '70%'],
        avoidLabelOverlap: true,
        itemStyle: { borderColor: '#0a0f1e', borderWidth: 2 },
        label: { color: '#e2e8f0', fontSize: 11 },
        data: [
          { value: s.contenidas, name: 'Contenidas', itemStyle: { color: '#22c55e' } },
          { value: s.total - s.contenidas, name: 'Sin contención total', itemStyle: { color: '#ef4444' } },
        ],
      },
    ],
  })

  // ── Gráfico de barras: infectados vs a salvo promedio (comparado por valor) ──
  ecInfSal.setOption({
    backgroundColor: 'transparent',
    tooltip: { trigger: 'axis' },
    legend: { data: ['Infectados', 'A salvo'], textStyle: { color: '#94a3b8', fontSize: 10 }, top: 4 },
    grid: { left: 44, right: 16, top: 40, bottom: 36 },
    xAxis: { type: 'category', data: labels, axisLabel: { color: '#94a3b8', fontSize: 10 } },
    yAxis: { type: 'value', axisLabel: { color: '#94a3b8', fontSize: 10 }, splitLine: { lineStyle: { color: '#1e293b' } } },
    series: [
      { name: 'Infectados', type: 'bar', stack: 'total', data: resumenPorValor.value.map(r => formatNum(r.avgInfectados) ?? 0), itemStyle: { color: '#ef4444' } },
      { name: 'A salvo', type: 'bar', stack: 'total', data: resumenPorValor.value.map(r => formatNum(r.avgAsalvo) ?? 0), itemStyle: { color: '#22c55e' } },
    ],
  })
}

// Re-renderizar gráficos cuando cambie el filtro o el agrupamiento
watch([agruparPor, valorSeleccionado], async () => {
  await nextTick()
  renderCharts()
})

onMounted(() => {
  cargarDatos()
  window.addEventListener('resize', handleResize)
})

function handleResize() {
  ecResumen?.resize()
  ecPie?.resize()
  ecInfSal?.resize()
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600&family=Inter:wght@400;500;600&display=swap');

* { box-sizing: border-box; }
.stats-page { min-height: calc(100vh - 46px); background: #0a0f1e; color: #e2e8f0; font-family: 'Inter', sans-serif; padding: 20px 24px 40px; display: flex; flex-direction: column; gap: 18px; }

.stats-header { display: flex; align-items: center; justify-content: space-between; }
.stats-tag { font-family: 'JetBrains Mono', monospace; font-size: 10px; color: #f97316; letter-spacing: 0.1em; text-transform: uppercase; display: block; margin-bottom: 2px; }
.stats-title { font-size: 20px; font-weight: 600; color: #f1f5f9; }
.stats-subtitle { font-size: 12px; color: #64748b; margin-top: 4px; }

.refresh-button {
  border: 1px solid #334155; background: transparent; color: #cbd5e1; border-radius: 999px;
  padding: 9px 16px; cursor: pointer; font-family: 'JetBrains Mono', monospace; font-size: 11px;
  text-transform: uppercase; letter-spacing: 0.08em; transition: all 0.2s ease;
}
.refresh-button:hover:not(:disabled) { background: rgba(148, 163, 184, 0.08); color: #f1f5f9; }
.refresh-button:disabled { opacity: 0.5; cursor: default; }

.stats-state { padding: 28px; text-align: center; color: #cbd5e1; border: 1px dashed #334155; border-radius: 14px; }
.stats-state.error { color: #fca5a5; }

.controls-card {
  display: flex; gap: 24px; flex-wrap: wrap; align-items: flex-end;
  background: #0d1526; border: 1px solid #1e293b; border-radius: 14px; padding: 16px 20px;
}
.control-group { display: flex; flex-direction: column; gap: 6px; }
.control-group label { font-family: 'JetBrains Mono', monospace; font-size: 10px; color: #64748b; text-transform: uppercase; letter-spacing: 0.08em; }

.segmented { display: flex; border: 1px solid #334155; border-radius: 999px; overflow: hidden; }
.segmented button {
  border: none; background: transparent; color: #94a3b8; padding: 8px 16px; cursor: pointer;
  font-family: 'JetBrains Mono', monospace; font-size: 11px; text-transform: uppercase; letter-spacing: 0.06em;
  transition: all 0.2s ease;
}
.segmented button.active { background: #f97316; color: #0a0f1e; font-weight: 700; }

.select-input {
  background: #0a0f1e; border: 1px solid #334155; color: #e2e8f0; border-radius: 8px;
  padding: 8px 12px; font-family: 'JetBrains Mono', monospace; font-size: 12px; min-width: 220px;
}

.section-label { font-family: 'JetBrains Mono', monospace; font-size: 10px; color: #475569; text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 8px; }

.chart-card { background: #0d1526; border: 1px solid #1e293b; border-radius: 14px; padding: 16px 18px; }
.chart-box { width: 100%; height: 260px; }

.charts-row { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; }
.chart-card.half { min-width: 0; }
@media (max-width: 860px) { .charts-row { grid-template-columns: 1fr; } }

.detail-grid { display: grid; grid-template-columns: repeat(6, 1fr); gap: 12px; }
@media (max-width: 1100px) { .detail-grid { grid-template-columns: repeat(3, 1fr); } }
@media (max-width: 620px) { .detail-grid { grid-template-columns: repeat(2, 1fr); } }

.stat-card {
  background: #0d1526; border: 1px solid #1e293b; border-radius: 12px; padding: 14px;
  display: flex; flex-direction: column; gap: 4px; text-align: center;
}
.stat-card-value { font-family: 'JetBrains Mono', monospace; font-size: 20px; font-weight: 700; color: #f1f5f9; }
.stat-card-label { font-size: 10px; color: #64748b; text-transform: uppercase; letter-spacing: 0.05em; }
.stat-card.success .stat-card-value { color: #22c55e; }
.stat-card.danger .stat-card-value { color: #ef4444; }

.table-card { background: #0d1526; border: 1px solid #1e293b; border-radius: 14px; padding: 16px 18px; }
.table-frame { overflow: auto; border: 1px solid #1e293b; border-radius: 10px; max-height: 420px; }
.stats-table { width: 100%; border-collapse: collapse; min-width: 760px; font-family: 'JetBrains Mono', monospace; }
.stats-table th, .stats-table td { padding: 10px 12px; border-bottom: 1px solid #1e293b; text-align: left; font-size: 11px; }
.stats-table th { position: sticky; top: 0; background: #0d1526; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.06em; font-size: 9px; }
.stats-table td { color: #e2e8f0; }
</style>
