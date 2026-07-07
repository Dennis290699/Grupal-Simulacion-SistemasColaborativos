<template>
  <div ref="container" class="cy-container"></div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import cytoscape from 'cytoscape'
import { fetchCSVSkipFirstLine, cleanRow } from '../components/usePolling'
import { ICON_PC, ICON_PC_INFECTED, ICON_PC_ISOLATED, ICON_FIREWALL, ICON_FIREWALL_INFECTED, ICON_FIREWALL_ISOLATED, ICON_SWITCH, ICON_SWITCH_INFECTED, ICON_SWITCH_ISOLATED, ICON_CLOUD, ICON_SERVER, ICON_SERVER_INFECTED, ICON_SERVER_ISOLATED } from '../utils/icons'

// ════════════════════════════════════════════════════════════════
// CytoscapeMap - Visualización de la Topología de Red
// ════════════════════════════════════════════════════════════════

const props = defineProps({ base: { type: String, default: '/results' } })
const emit = defineEmits(['ready', 'init'])

const container = ref(null)  // Referencia DOM para Cytoscape
let cy = null               // Instancia de Cytoscape

function cyStyles() {
  return [
    {
      selector: 'node',
      style: {
        label: 'data(label)',           // Nombre del nodo debajo del ícono
        'font-size': '40px',
        'font-family': 'monospace',
        color: '#e2e8f0',
        'text-valign': 'bottom',        // Texto alineado abajo
        'text-margin-y': '10px',
        width: '60px',
        height: '60px',
        shape: 'rectangle',             // Contenedor rectangular
        'background-fit': 'contain',    // Ajustar ícono SVG al espacio
        'background-clip': 'none',
        'background-opacity': 0,        // Fondo transparente
        'border-width': 0,
        'background-image': ICON_PC    // Ícono por defecto
      }
    },
    
    // ─────────────────────────────────────────────────────────
    // Estilos por tipo de nodo (sin infectar)
    // ─────────────────────────────────────────────────────────
    { selector: 'node[tipo="pc"]', style: { 'background-image': ICON_PC, width: '120px', height: '120px' } },
    { selector: 'node[tipo="server"]', style: { 'background-image': ICON_SERVER, width: '120px', height: '120px' } },
    { selector: 'node[tipo="firewall"]', style: { 'background-image': ICON_FIREWALL, width: '120px', height: '120px' } },
    { selector: 'node[tipo="switch"]', style: { 'background-image': ICON_SWITCH, width: '120px', height: '120px' } },
    { selector: 'node[tipo="internet"]', style: { 'background-image': ICON_CLOUD, width: '120px', height: '120px' } },

    // ─────────────────────────────────────────────────────────
    // Estados infectados: combina clase .infected + tipo
    // ─────────────────────────────────────────────────────────
    { selector: 'node.infected[tipo="pc"]', style: { 'background-image': ICON_PC_INFECTED } },
    { selector: 'node.infected[tipo="firewall"]', style: { 'background-image': ICON_FIREWALL_INFECTED } },
    { selector: 'node.infected[tipo="switch"]', style: { 'background-image': ICON_SWITCH_INFECTED } },
    { selector: 'node.infected[tipo="server"]', style: { 'background-image': ICON_SERVER_INFECTED } },

    // ─────────────────────────────────────────────────────────
    // Estados aislados: combina clase .isolated + tipo
    // ─────────────────────────────────────────────────────────
    { selector: 'node.isolated[tipo="pc"]', style: { 'background-image': ICON_PC_ISOLATED } },
    { selector: 'node.isolated[tipo="firewall"]', style: { 'background-image': ICON_FIREWALL_ISOLATED } },
    { selector: 'node.isolated[tipo="switch"]', style: { 'background-image': ICON_SWITCH_ISOLATED } },
    { selector: 'node.isolated[tipo="server"]', style: { 'background-image': ICON_SERVER_ISOLATED } },

    // ─────────────────────────────────────────────────────────
    // Aristas (conexiones entre nodos)
    // ─────────────────────────────────────────────────────────
    {
      selector: 'edge',
      style: {
        width: 3,
        'line-color': '#f97316',          
        'target-arrow-color': '#f97316',
        'target-arrow-shape': 'triangle',  
        'curve-style': 'bezier',          
        opacity: 0.8,
      },
    },
    {
      selector: 'edge.attack',
      style: {
        'line-color': '#ef4444',          
        'target-arrow-color': '#ef4444',
        width: 6,                                  
        opacity: 1,
        'line-style': 'solid'
      }
    }
  ]
}

/**
 * Inicializa el grafo de red desde los CSV:
 */
async function initCytoscape() {
  if (!container.value) return   // Guarda de seguridad: si el DOM no está listo, no sigas

  try {
    const [nodosRaw, topoRaw] = await Promise.all([
      fetchCSVSkipFirstLine(`${props.base}/log_nodos.csv`),
      fetchCSVSkipFirstLine(`${props.base}/log_topologia.csv`),
    ])

    const nodos = nodosRaw.map(cleanRow).filter(n => n.nombre && n.nombre !== '')
    const topo = topoRaw.map(cleanRow).filter(t => t.origen && t.destino && t.origen !== '' && t.destino !== '')

    const nodoEstado = {}
    nodos.forEach(n => {
      nodoEstado[n.nombre] = {
        tipo: n.tipo,
        infected: false,
        isolated: false,
        is_internet: n.tipo === 'internet'
      }
    })

    const elements = [
      ...nodos.map(n => ({ data: { id: n.nombre, label: n.nombre, tipo: n.tipo } })),
      ...topo.map(t => ({ data: { id: `${t.origen}-${t.destino}`, source: t.origen, target: t.destino } })),
    ]

    if (cy) { cy.destroy(); cy = null }   // Destruye instancia previa si existiera (HMR)

    cy = cytoscape({
      container: container.value,
      elements,
      style: cyStyles(),
      layout: { name: 'breadthfirst', directed: false, padding: 60, spacingFactor: 2.8 },
      userZoomingEnabled: true,
      userPanningEnabled: true
    })

    const internetNodo = nodos.find(n => n.tipo === 'internet')
    if (internetNodo) {
      nodoEstado[internetNodo.nombre].infected = true
      const node = cy.getElementById(internetNodo.nombre)
      if (node && node.length) node.addClass('infected')
    }

    emit('init', nodoEstado)
    emit('ready')
  } catch (error) {
    console.error("Error cargando los datos de la topología:", error)
  }
}

/**
 * Actualiza visualización de un nodo individual.
 */
function updateNode(nombre, infected, isolated) {
  if (!cy) return
  
  const node = cy.getElementById(nombre)
  if (!node || !node.length) return
  
  // Remover clases previas
  node.removeClass('infected isolated')
  
  if (isolated) {
    node.addClass('isolated')
  } else if (infected) {
    node.addClass('infected')
    
    // Capturar tamaño original
    const baseW = node.numericStyle('width')
    const baseH = node.numericStyle('height')
    
    // Animar: crecer → volver a tamaño original
    node.animate(
      { style: { width: baseW * 1.4, height: baseH * 1.4 } },
      { duration: 300, complete: function () {
        node.animate(
          { style: { width: baseW, height: baseH } },
          { duration: 300 }
        )
      }}
    )
  }
}

/**
 * Marca una arista como "attack" para mostrar ataque en progreso.
 */
function markAttackEdge(desde, nodo) {
  if (!cy || !desde || !nodo) return
  
  const edge = cy.edges().filter(e =>
    ((e.data('source') === desde && e.data('target') === nodo) ||
     (e.data('source') === nodo && e.data('target') === desde))
  )
  
  if (edge.length) edge.addClass('attack')
}

function resizeFit() {
  if (!cy) return
  cy.resize()
  cy.fit(undefined, 40)
}

// Inicializar Cytoscape de forma segura cuando el componente se monta en el DOM
onMounted(() => {
  initCytoscape()
})

onBeforeUnmount(() => {
  if (cy) { cy.destroy(); cy = null }
})

// Exponer métodos públicos al padre
defineExpose({ updateNode, markAttackEdge, resizeFit })
</script>

<style scoped>
.cy-container { width: 100%; height: 600px; background: #0d1526; border: 1px solid #1e293b; border-radius: 8px; }
</style>