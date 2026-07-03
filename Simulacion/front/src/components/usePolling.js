import Papa from 'papaparse'

export function cleanRow(row) {
  const out = {}
  Object.keys(row).forEach(k => {
    out[k.trim()] = typeof row[k] === 'string' ? row[k].trim() : row[k]
  })
  return out
}

function limpiarLinea(line) {
  return (line || '').replace(/^['"]+|['"]+$/g, '').trim()
}

// GAMA agrega una línea "artefacto" antes del header real cuando haces
// save de un string con rewrite:true:
//  - si es una variable (save encabezado_evt to: ...) -> escribe el
//    NOMBRE de la variable como línea 0 (ej: "encabezado_evt", sin comas)
//  - si es un literal (save "id,nombre,tipo" to: ...) -> escribe el
//    TEXTO citado como línea 0 (ej: 'id,nombre,tipo', duplicado del real)
// Esta función detecta y descarta esa línea en ambos casos, tolerando
// además BOM, CRLF, y posibles líneas vacías entre el artefacto y el
// header real.
function stripGamaHeaderBug(text) {
  let lines = text.replace(/^\uFEFF/, '').split(/\r?\n/)

  while (lines.length && lines[0].trim() === '') lines.shift()
  if (lines.length < 2) return lines.join('\n')

  const line0 = limpiarLinea(lines[0])

  for (let i = 1; i <= 3 && i < lines.length; i++) {
    if (lines[i].trim() === '') continue
    const lineI = limpiarLinea(lines[i])

    const esDuplicadoLiteral = line0 === lineI
    const esNombreVariable = !line0.includes(',') && lineI.includes(',')

    if (esDuplicadoLiteral || esNombreVariable) {
      return lines.slice(i).join('\n')
    }
    break
  }

  return lines.join('\n')
}

export async function fetchCSV(path) {
  const noCache = path.includes('?') ? `${path}&t=${Date.now()}` : `${path}?t=${Date.now()}`
  const res = await fetch(noCache, { cache: 'no-store' })
  const text = await res.text()
  const textoLimpio = stripGamaHeaderBug(text)

  return new Promise((resolve, reject) => {
    Papa.parse(textoLimpio, {
      header: true,
      skipEmptyLines: true,
      transformHeader: h => h.trim(),
      complete: r => {
        const headers = r.meta.fields || []
        const rows = r.data.filter(row =>
          !headers.every(h => (row[h] ?? '').toString().trim() === h)
        )
        resolve(rows)
      },
      error: reject,
    })
  })
}

export const fetchCSVSkipFirstLine = fetchCSV