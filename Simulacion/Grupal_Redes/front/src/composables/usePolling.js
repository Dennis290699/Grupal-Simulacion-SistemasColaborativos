import Papa from 'papaparse'

// ════════════════════════════════════════════════════════════════
// usePolling - Utilidades para Carga y Procesamiento de CSV
// ════════════════════════════════════════════════════════════════
// Responsabilidades:
// • Normalizar espacios en datos CSV (trim de claves y valores)
// • Descargar y parsear archivos CSV con PapaParse
// • Manejar variantes de formato CSV (con/sin líneas basura)
// ════════════════════════════════════════════════════════════════

/**
 * Normaliza una fila de datos CSV.
 * 
 * OPERACIONES:
 *   • Trim() en todas las claves (ej. ' nodo ' → 'nodo')
 *   • Trim() en todos los valores string (limpia espacios)
 *   • Deja números y otros tipos sin cambios
 *
 * ¿POR QUÉ?
 *   Los archivos CSV a veces tienen espacios inconsistentes por
 *   exportación de Excel, bases de datos, etc. Esto normaliza
 *   para evitar comparaciones fallidas (ej. ' infectado' != 'infectado')
 *
 * @param {Object} row - Fila con claves/valores crudos
 * @returns {Object} Fila normalizada
 * @example
 *   cleanRow({ ' nodo ': ' PC1 ', ' infectados ': '5' })
 *   // → { 'nodo': 'PC1', 'infectados': '5' }
 */
export function cleanRow(row) {
  const out = {}
  Object.keys(row).forEach(k => {
    out[k.trim()] = typeof row[k] === 'string' ? row[k].trim() : row[k]
  })
  return out
}

/**
 * Descarga y parsea un archivo CSV usando PapaParse.
 * 
 * CONFIGURACIÓN:
 *   • download: true → fetch automático desde URL
 *   • header: true → primera fila como headers (keys de objetos)
 *   • skipEmptyLines: true → ignora filas vacías
 *   • transformHeader: trim de headers → evita ' nodo ' como clave
 *
 * RETORNO:
 *   Promise que resuelve a array de objetos (filas parseadas)
 *
 * CASOS DE USO:
 *   • fetchCSV('/results/log_eventos.csv') → tabla de eventos
 *   → carga normal que puede tener headers en primera línea
 *
 * @param {string} path - URL relativa del CSV
 * @returns {Promise<Array>} Array de filas como objetos
 */
export function fetchCSV(path) {
  return new Promise((resolve, reject) => {
    Papa.parse(path, {
      download: true,      // Permitir descargas de URL
      header: true,        // Usar primera fila como headers
      skipEmptyLines: true,
      transformHeader: h => h.trim(),  // Limpiar nombres de columnas
      complete: r => resolve(r.data),
      error: reject,
    })
  })
}

/**
 * Variante especial que maneja archivos CSV con líneas "basura" al inicio.
 *
 * PROBLEMA:
 *   Algunos CSV exportados tienen metadatos o comentarios antes de
 *   los datos reales. Ejemplo:
 *     ```
 *     Reporte generado 2026-06-24
 *     nombre,tipo,infectado
 *     PC1,pc,0
 *     ```
 *   Si parseamos directamente, la primera línea se interpreta como header.
 *
 * SOLUCIÓN:
 *   1. Fetch completo como texto
 *   2. Split por líneas
 *   3. Detectar si primera línea es "basura" (sin comas)
 *   4. Si es basura, remover y parsear el resto
 *   5. Si no tiene basura, parsear normal
 *
 * DETECCIÓN DE BASURA:
 *   • trim() la primera línea
 *   • Si NO contiene ',', asumir que es un comentario/metadato
 *   • Skip esa línea
 *
 * CASOS DE USO:
 *   • fetchCSVSkipFirstLine('/results/log_nodos.csv') → con metadatos
 *   • fetchCSVSkipFirstLine('/results/log_topologia.csv') → con headers feos
 *
 * @param {string} path - URL relativa del CSV
 * @returns {Promise<Array>} Array de filas como objetos
 */
export function fetchCSVSkipFirstLine(path) {
  return fetch(path)
    .then(r => r.text())
    .then(text => {
      // Dividir por líneas
      const lines = text.split('\n')
      
      // Inspeccionar primera línea
      const primeraLinea = lines[0]?.trim()
      
      // ¿Parece basura? (no tiene comas = no es CSV válido)
      const esBasura = primeraLinea && !primeraLinea.includes(',')
      
      // Limpiar texto: skip línea basura si existe
      const textoLimpio = esBasura ? lines.slice(1).join('\n') : text
      
      // Parsear el texto limpio
      return new Promise((resolve, reject) => {
        Papa.parse(textoLimpio, {
          header: true,
          skipEmptyLines: true,
          transformHeader: h => h.trim(),
          complete: r => resolve(r.data),
          error: reject,
        })
      })
    })
}
