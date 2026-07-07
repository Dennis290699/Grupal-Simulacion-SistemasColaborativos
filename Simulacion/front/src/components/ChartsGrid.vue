<template>
  <div class="charts-section">
    <div class="chart-card">
      <div class="chart-label">Infectados por ciclo</div>
      <div ref="infectados" class="chart-box"></div>
    </div>
    <div class="chart-card">
      <div class="chart-label">Patch level promedio</div>
      <div ref="patch" class="chart-box"></div>
    </div>
    <div class="chart-card">
      <div class="chart-label">Intenciones BDI</div>
      <div ref="intenciones" class="chart-box"></div>
    </div>
    <div class="chart-card events-card">
      <div class="chart-label">Eventos en tiempo real</div>
      <div class="events-table-wrap">
        <table class="events-table">
          <thead>
            <tr>
              <th>Ciclo</th>
              <th>Nodo</th>
              <th>Evento</th>
              <th>Desde</th>
              <th>P</th>
            </tr>
          </thead>
          <tbody>
            <slot name="events" />
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick } from 'vue'

// ════════════════════════════════════════════════════════════════
// ChartsGrid - Contenedor de Gráficos ECharts y Tabla de Eventos
// ════════════════════════════════════════════════════════════════

// Crear 3 refs reactivas para los contenedores de gráficos
const infectados = ref(null)
const patch = ref(null)
const intenciones = ref(null)

// Definir eventos que este componente puede emitir al padre
const emit = defineEmits(['mounted'])

onMounted(async () => {
  await nextTick()  // Garantiza que Vue terminó el render
  emit('mounted')   // Señala al padre que está listo para init
})

// Expone las 3 refs de contenedores al padre (App.vue)
// para que initCharts() pueda hacer echarts.init(infectados, ...)
defineExpose({ infectados, patch, intenciones })
</script>

<style scoped>
.charts-section { display: grid; grid-template-columns: 1fr 1fr 1fr 1fr; gap: 12px; padding: 8px 24px 24px; }
.chart-card { background: #0d1526; border: 1px solid #1e293b; border-radius: 8px; padding: 12px; display:flex; flex-direction: column; gap: 8px }
.chart-label {
  font-family: 'JetBrains Mono', monospace;
  font-size: 10px;
  color: #475569;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}
.chart-box { height: 180px }
.events-card { overflow: hidden; }
.events-table-wrap { height: 180px; overflow-y: auto; scrollbar-width: thin; scrollbar-color: #1e293b transparent; }
.events-table { width: 100%; border-collapse: collapse; font-size: 11px; font-family: 'JetBrains Mono', monospace }
.events-table th {
  position: sticky;
  top: 0;
  background: #0d1526;
  color: #475569;
  text-align: left;
  padding: 4px 6px;
  font-size: 10px;
  text-transform: uppercase;
  border-bottom: 1px solid #1e293b;
}
.events-table td { padding: 4px 6px; color: #94a3b8; border-bottom: 1px solid #0f172a; }
</style>
