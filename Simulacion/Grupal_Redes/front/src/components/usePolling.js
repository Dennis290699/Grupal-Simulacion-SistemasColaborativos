import Papa from 'papaparse'

// Limpia espacios en claves y valores de una fila parseada por PapaParse
export function cleanRow(row) {
  const out = {}
  Object.keys(row).forEach(k => {
    out[k.trim()] = typeof row[k] === 'string' ? row[k].trim() : row[k]
  })
  return out
}

// Parser estándar para CSV que SÍ tienen un encabezado real en la primera línea
// (ej. log_eventos.csv)
export function fetchCSV(path) {
  return new Promise((resolve, reject) => {
    Papa.parse(path, {
      download: true,
      header: true,
      skipEmptyLines: true,
      transformHeader: h => h.trim(),
      complete: r => resolve(r.data),
      error: reject,
    })
  })
}

// Parser para CSV que traen una primera línea "basura" sin comas
// (ej. log_nodos.csv / log_topologia.csv generados por GAMA)
export async function fetchCSVSkipFirstLine(path) {
  const res = await fetch(path)
  const text = await res.text()
  const lines = text.split('\n')

  const primeraLinea = lines[0]?.trim()
  const esBasura = primeraLinea && !primeraLinea.includes(',')
  const textoLimpio = esBasura ? lines.slice(1).join('\n') : text

  return new Promise((resolve, reject) => {
    Papa.parse(textoLimpio, {
      header: true,
      skipEmptyLines: true,
      transformHeader: h => h.trim(),
      complete: r => resolve(r.data),
      error: reject,
    })
  })
}
