# Pull Request: Modularización + Comentarios Completos

**Fecha:** 2026-06-24  
**Tipo:** Refactoring + Documentation  
**Rama:** main  

---

## 📋 Resumen

Se completó la **modularización de la aplicación Vue** y se agregaron **comentarios explicativos detallados** en todos los archivos clave. La app ahora es más limpia, reutilizable y fácil de mantener.

### Logros
✅ **Componentes modularizados** con responsabilidades claras  
✅ **Ciclo de vida de gráficos** funcionando correctamente  
✅ **Encuesta de datos** (polling) en tiempo real  
✅ **Documentación inline** en todos los archivos  

---

## 🗂️ Archivos Modificados y Comentarios

### 1. **src/App.vue** - Orquestador Central
**Responsabilidades:**
- Coordinar ciclo de vida de componentes hijo
- Gestionar encuesta periódica de datos CSV
- Actualizar gráficos ECharts en tiempo real
- Mantener estado de la red (infectados/aislados)

**Secciones Comentadas:**
```javascript
// ════════════════════════════════════════════════════════════════
// WannaCry Network Simulation Dashboard - Componente Principal
// ════════════════════════════════════════════════════════════════
// Coordinador central que gestiona:
// • Ciclo de vida de gráficos (ECharts) con timing garantizado
// • Encuesta periódica de datos CSV (log_eventos.csv)
// • Estado de nodos de red (Cytoscape) e infecciones
// • Comunicación entre componentes hijo
```

**Funciones Importantes Documentadas:**
- `onChartsMounted()` - Callback cuando ChartsGrid está listo
- `waitForChartRefs()` - Polling activo esperando a que DOM esté disponible
- `initCharts()` - Inicializa 3 instancias ECharts
- `startPolling()` - Comienza encuesta periódica (2s)
- `pollCSV()` - Descarga log_eventos.csv y procesa cambios
- `procesarEvento()` - Actualiza estado de nodos según eventos
- `updateCharts()` - Actualiza series de datos en gráficos

---

### 2. **src/components/ChartsGrid.vue** - Contenedor de Gráficos
**Responsabilidades:**
- Proporcionar 3 contenedores DOM para gráficos ECharts
- Emitir evento `mounted` cuando DOM está listo
- Exponer refs de contenedores al padre

**Secciones Comentadas:**
```javascript
/**
 * Ciclo de vida: emite evento 'mounted' una vez que el DOM está listo.
 * ¿POR QUÉ ESTO ES IMPORTANTE?
 *   • Antes: watch(chartsRef) nunca se disparaba (ref no muta)
 *   • Ahora: evento explícito garantiza timing seguro
 * El patrón es más robusto que watch porque es explícito.
 */
```

**Concepto Clave:**
- Explicación del pattern: evento ready vs watch
- Por qué un watch sobre refs no funciona
- Cómo el evento 'mounted' resuelve el problema

---

### 3. **src/components/CytoscapeMap.vue** - Visualización de Red
**Responsabilidades:**
- Cargar nodos y topología desde CSV
- Renderizar grafo con Cytoscape.js
- Aplicar estilos dinámicos (infected, isolated, sano)
- Exponer métodos para actualizar visualización

**Secciones Comentadas:**
```javascript
/**
 * Define los estilos visuales de nodos y aristas del grafo.
 * ESTRATEGIA DE ICONOS:
 *   • Data URIs (SVG en base64)
 *   • Se intercambian según tipo + estado
 *   • Ejemplo: PC normal → ICON_PC, PC infectado → ICON_PC_INFECTED
 */

/**
 * Actualiza visualización de un nodo individual.
 * LÓGICA:
 *   • Si isolated=true: muestra ícono de aislado + animación
 *   • Si infected=true: muestra ícono infectado + pulse
 *   • Si ambos false: muestra ícono sano
 * 
 * ANIMACIÓN:
 *   • Al infectar: crece 1.4x, vuelve en 600ms
 *   • Efecto visual: "pulso" de infección propagándose
 */
```

**Funciones Documentadas:**
- `cyStyles()` - Estilos por tipo de nodo y estado
- `initCytoscape()` - Inicialización del grafo
- `updateNode()` - Actualizar ícono y animar
- `markAttackEdge()` - Marcar arista como ataque
- `resizeFit()` - Redimensionar viewport

---

### 4. **src/composables/usePolling.js** - Utilidades CSV
**Responsabilidades:**
- Normalizar datos CSV (trim de espacios)
- Descargar y parsear archivos CSV
- Manejar variantes de formato

**Secciones Comentadas:**
```javascript
/**
 * Normaliza una fila de datos CSV.
 * ¿POR QUÉ?
 *   Los CSV a veces tienen espacios inconsistentes.
 *   Esto normaliza para evitar comparaciones fallidas.
 *   ' infectado' != 'infectado'
 */

/**
 * Variante especial que maneja líneas "basura" al inicio.
 * PROBLEMA:
 *   Algunos CSV exportados tienen metadatos o comentarios.
 * SOLUCIÓN:
 *   1. Fetch como texto
 *   2. Detectar si primera línea es basura (sin comas)
 *   3. Skip línea si es basura
 *   4. Parsear el resto
 */
```

**Funciones Documentadas:**
- `cleanRow()` - Normalizar espacios
- `fetchCSV()` - Descargar y parsear CSV normal
- `fetchCSVSkipFirstLine()` - Manejar CSV con metadatos

---

### 5. **src/utils/icons.js** - Iconos SVG
**Responsabilidades:**
- Centralizar todos los iconos de nodos de red
- Proporcionar 3 variantes por tipo (normal, infectado, aislado)
- Convertir SVG a data URIs en base64

**Secciones Comentadas:**
```javascript
/**
 * PC Sano: borde verde, pantalla clara
 * Simboliza: equipo funcional y limpio
 */
export const ICON_PC = svgToDataUri(`...`)

/**
 * PC Infectado: borde rojo, símbolo "!" en pantalla
 * Simboliza: equipo comprometido, malware activo
 */
export const ICON_PC_INFECTED = svgToDataUri(`...`)

/**
 * PC Aislado: borde gris, línea diagonal tachada
 * Simboliza: equipo desconectado para contención
 */
```

**Iconos Documentados:**
- **PC (Computadora)**: 3 variantes (normal, infectado, aislado)
- **Firewall**: 3 variantes (defensa activa → comprometida → offline)
- **Switch**: 3 variantes (puertos verdes → rojos → grises)
- **Cloud/Internet**: siempre amarillo (fuente del ataque)
- **Server**: 3 variantes (operativo → caído → offline)

---

### 6. **src/components/VIcon.vue** - Componente Wrapper MDI
**Responsabilidades:**
- Envolver iconos Material Design Icons (MDI)
- Proporcionar props para size, color, alignment
- Normalizar uso de iconos

**Secciones Comentadas:**
```javascript
/**
 * Calcula las clases CSS del ícono.
 * LÓGICA:
 *   1. Si icon NO tiene 'mdi-', agregar prefijo
 *   2. Combinar 'mdi' base + nombre normalizado
 *   3. Filtrar valores nulos/vacíos
 *
 * icon='monitor' → 'mdi mdi-monitor'
 * icon='mdi-monitor' → 'mdi mdi-monitor'
 */

/**
 * Construye objeto de estilos inline.
 * PROCESAMIENTO:
 *   • Número + string → conversión a px
 *   • Solo incluir propiedades no-null
 *   • Retornar objeto JS para v-bind:style
 */
```

**Props Documentadas:**
- `icon` - Nombre del ícono (con/sin prefijo)
- `size` - Tamaño en px o em
- `color` - Color CSS
- `minWidth` - Ancho mínimo
- `height` - Altura (line-height)

---

## 🔄 Estructura de Componentes

```
App.vue (Orquestador)
├── CytoscapeMap.vue (Grafo de red)
│   ├── icons.js (Iconos SVG)
│   └── usePolling.js (Cargar nodos/topología CSV)
│
├── ChartsGrid.vue (Contenedor gráficos)
│   ├── ECharts (3 instancias)
│   └── Tabla de eventos
│
└── usePolling.js (Composable)
    ├── cleanRow() - Normalizar CSV
    ├── fetchCSV() - Descargar eventos
    └── fetchCSVSkipFirstLine() - Cargar nodos/topología
```

---

## 📊 Patrones Documentados

### 1. **Patrón Ready Event** (ChartsGrid → App.vue)
```javascript
// Hijo emite cuando está listo
onMounted(async () => {
  await nextTick()
  emit('mounted')
})

// Padre escucha y actúa
<ChartsGrid @mounted="onChartsMounted" />
```

**Por qué funciona mejor que watch:**
- Explícito: comunica claramente cambios importantes
- Confiable: ref no muta tras setup
- Debuggeable: fácil de rastrear en DevTools

---

### 2. **Patrón Polling Activo** (waitForChartRefs)
```javascript
function waitForChartRefs(maxTries = 30) {
  return new Promise((resolve) => {
    let tries = 0
    function check() {
      const infectEl = chartsRef.value?.infectados
      if (infectEl && patchEl && intencionesEl) {
        resolve()
        return
      }
      tries++
      if (tries >= maxTries) {
        resolve() // Resolver igual para no colgar
        return
      }
      requestAnimationFrame(check)  // Sincronizar con frames
    }
    requestAnimationFrame(check)
  })
}
```

**Ventajas:**
- Más robusto que `nextTick()` (cubre concurrencia)
- `requestAnimationFrame` vs `setTimeout` (eficiencia)
- Fallback graceful (maxTries)

---

### 3. **Normalización CSV** (cleanRow)
```javascript
export function cleanRow(row) {
  const out = {}
  Object.keys(row).forEach(k => {
    out[k.trim()] = typeof row[k] === 'string' ? row[k].trim() : row[k]
  })
  return out
}
```

**Resuelve:**
- Espacios inconsistentes en exports de Excel
- Comparaciones fallidas (' infectado' != 'infectado')
- Normalización automática en toda la app

---

### 4. **Data URIs SVG** (icons.js)
```javascript
function svgToDataUri(svg) {
  return 'data:image/svg+xml;base64,' + btoa(svg)
}

export const ICON_PC = svgToDataUri(`<svg>...</svg>`)
```

**Ventajas:**
- No requiere HTTP requests adicionales
- Se incrusta directamente en CSS
- Compatible con Cytoscape background-image

---

## 🧪 Validación

| Aspecto | Status |
|--------|--------|
| Build | ✅ `npm run build` sin errores |
| Lint | ✅ Sintaxis correcta |
| Comentarios | ✅ Todas las secciones clave documentadas |
| Tipos | ✅ Props con comentarios JSDoc |
| Funciones | ✅ Cada función explicada |

---

## 📚 Estructura de Documentación

Cada archivo tiene:

1. **Header comentado**: Propósito y responsabilidades
   ```javascript
   // ════════════════════════════════════════════════════════════════
   // ComponentName - Descripción
   // ════════════════════════════════════════════════════════════════
   // Responsabilidades:
   // • ...
   // • ...
   ```

2. **Secciones marcadas**: Divididas por funcionalidad
   ```javascript
   // ─── SECCIÓN: Descripción ─────────────────────────────
   ```

3. **JSDoc en funciones**: Parámetros, retorno, ejemplos
   ```javascript
   /**
    * Descripción breve
    * 
    * LÓGICA/FLUJO:
    *   1. Paso uno
    *   2. Paso dos
    * 
    * @param {type} name - Descripción
    * @returns {type} Descripción
    * @example
    *   usage()
    */
   ```

4. **Comentarios inline**: "Por qué" más que "qué"
   ```javascript
   if (condition) {
     // ¿POR QUÉ?: explicar la razón de negocio
   }
   ```

---

## 🚀 Ventajas Post-Refactoring

| Aspecto | Antes | Después |
|--------|-------|---------|
| **Modularidad** | Monolítico | Componentes reutilizables |
| **Legibilidad** | Código sin contexto | Documentación completa |
| **Mantenimiento** | Difícil de entender | Secciones claramente marcadas |
| **Debugging** | Tenía que leer todo | JSDoc + ejemplos |
| **Onboarding** | Confuso | Nuevos devs entienden rápido |

---

## 📝 Notas de Desarrollo

### Para el próximo desarrollador:

1. **Ciclo de vida de gráficos** → Ver `App.vue` líneas 221-284
2. **Actualización de nodos** → Ver `CytoscapeMap.vue` función `updateNode()`
3. **Encuesta de datos** → Ver `App.vue` función `pollCSV()`
4. **Normalización CSV** → Ver `usePolling.js` función `cleanRow()`
5. **Estilos de iconos** → Ver `icons.js` comentarios para cada ícono

### Puntos críticos:

- ⚠️ `waitForChartRefs()` usa polling activo (no async/await simple)
- ⚠️ `pollingStarted` flag previene inicios duplicados
- ⚠️ Internet nodo siempre comienza infectado
- ⚠️ `requestAnimationFrame` vs `setTimeout` para eficiencia

---

## 🔗 Referencias

- **Vue 3**: Composition API con `<script setup>`
- **ECharts**: Gráficos en tiempo real
- **Cytoscape.js**: Visualización de grafos
- **PapaParse**: Parsing de CSV
- **Material Design Icons**: Librería de iconos

---

**Status**: ✅ LISTO PARA MERGE

**Commit Message Sugerido:**
```
feat: complete app modularization with detailed documentation

- Refactor components: CytoscapeMap, ChartsGrid, VIcon
- Add comprehensive JSDoc and inline comments
- Document all utility functions (cleanRow, fetchCSV, fetchCSVSkipFirstLine)
- Fix chart lifecycle with ready events and polling
- Centralize SVG icons with data URI strategy
- Add design patterns documentation
```
