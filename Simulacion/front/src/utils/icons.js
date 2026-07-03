// ════════════════════════════════════════════════════════════════
// Iconos SVG para Nodos de Red - Data URIs en Base64
// ════════════════════════════════════════════════════════════════
// Este módulo centraliza todos los iconos SVG usados en Cytoscape.
// Cada tipo de nodo (PC, Server, Firewall, etc.) tiene 3 variantes:
// • Normal (sano): color verde/azul
// • Infectado: color rojo + símbolo de alerta
// • Aislado: grisáceo + línea tachada
//
// ESTRATEGIA:
// • SVGs se convierten a data URIs en base64
// • Esto permite embedder imágenes sin HTTP requests adicionales
// • Cytoscape los usa en background-image del nodo
// ════════════════════════════════════════════════════════════════

/**
 * Convierte un string SVG a data URI en base64.
 * 
 * FORMATO:
 *   data:image/svg+xml;base64,[base64-encoded-svg]
 *
 * VENTAJAS:
 *   • No requiere HTTP requests adicionales
 *   • Se incrusta directamente en el CSS de Cytoscape
 *   • Compatible con background-image
 *
 * @param {string} svg - String SVG completo
 * @returns {string} Data URI usable en CSS
 * @example
 *   svgToDataUri('<svg>...</svg>')
 *   // → 'data:image/svg+xml;base64,PHN2Zz4uLi48L3N2Zz4='
 */
function svgToDataUri(svg) {
  return 'data:image/svg+xml;base64,' + btoa(svg)
}

// ════════════════════════════════════════════════════════════════
// ICONOS PC (Computadora Personal)
// ════════════════════════════════════════════════════════════════

/**
 * PC Sano: borde verde, pantalla clara
 * Simboliza: equipo funcional y limpio
 */
export const ICON_PC = svgToDataUri(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect x="8" y="10" width="48" height="32" rx="2" fill="#1e293b" stroke="#22c55e" stroke-width="2.5"/><rect x="13" y="15" width="38" height="22" fill="#0f172a"/><rect x="24" y="44" width="16" height="4" fill="#475569"/><rect x="16" y="48" width="32" height="4" rx="1" fill="#475569"/></svg>`)

/**
 * PC Infectado: borde rojo, símbolo "!" en pantalla
 * Simboliza: equipo comprometido, malware activo
 */
export const ICON_PC_INFECTED = svgToDataUri(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect x="8" y="10" width="48" height="32" rx="2" fill="#1e293b" stroke="#ef4444" stroke-width="2.5"/><rect x="13" y="15" width="38" height="22" fill="#450a0a"/><text x="32" y="31" font-size="16" fill="#ef4444" text-anchor="middle" font-family="monospace">!</text><rect x="24" y="44" width="16" height="4" fill="#475569"/><rect x="16" y="48" width="32" height="4" rx="1" fill="#475569"/></svg>`)

/**
 * PC Aislado: borde gris, línea diagonal tachada
 * Simboliza: equipo desconectado de la red para contención
 */
export const ICON_PC_ISOLATED = svgToDataUri(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect x="8" y="10" width="48" height="32" rx="2" fill="#1e293b" stroke="#475569" stroke-width="2.5"/><rect x="13" y="15" width="38" height="22" fill="#0f172a"/><line x1="6" y1="6" x2="58" y2="58" stroke="#475569" stroke-width="3"/><rect x="24" y="44" width="16" height="4" fill="#334155"/><rect x="16" y="48" width="32" height="4" rx="1" fill="#334155"/></svg>`)

// ════════════════════════════════════════════════════════════════
// ICONOS FIREWALL (Cortafuegos)
// ════════════════════════════════════════════════════════════════

/**
 * Firewall Sano: caja azul con 4 ondas (protección)
 * Simboliza: defensa activa, reglas aplicadas
 */
export const ICON_FIREWALL = svgToDataUri(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect x="10" y="8" width="44" height="48" rx="3" fill="#1e3a8a" stroke="#3b82f6" stroke-width="2.5"/><path d="M20 18 q6 -6 12 0 q6 -6 12 0" fill="none" stroke="#93c5fd" stroke-width="2"/><path d="M20 28 q6 -6 12 0 q6 -6 12 0" fill="none" stroke="#93c5fd" stroke-width="2"/><path d="M20 38 q6 -6 12 0 q6 -6 12 0" fill="none" stroke="#93c5fd" stroke-width="2"/><path d="M20 48 q6 -6 12 0 q6 -6 12 0" fill="none" stroke="#93c5fd" stroke-width="2"/></svg>`)

/**
 * Firewall Infectado: caja roja con ondas desvanecidas
 * Simboliza: defensa comprometida, virus atravesó el firewall
 */
export const ICON_FIREWALL_INFECTED = svgToDataUri(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect x="10" y="8" width="44" height="48" rx="3" fill="#7f1d1d" stroke="#ef4444" stroke-width="2.5"/><path d="M20 18 q6 -6 12 0 q6 -6 12 0" fill="none" stroke="#fca5a5" stroke-width="2"/><path d="M20 28 q6 -6 12 0 q6 -6 12 0" fill="none" stroke="#fca5a5" stroke-width="2"/><path d="M20 38 q6 -6 12 0 q6 -6 12 0" fill="none" stroke="#fca5a5" stroke-width="2"/><path d="M20 48 q6 -6 12 0 q6 -6 12 0" fill="none" stroke="#fca5a5" stroke-width="2"/></svg>`)

/**
 * Firewall Aislado: gris con línea diagonal
 * Simboliza: firewall desactivo/offline
 */
export const ICON_FIREWALL_ISOLATED = svgToDataUri(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect x="10" y="8" width="44" height="48" rx="3" fill="#1e293b" stroke="#475569" stroke-width="2.5"/><path d="M20 18 q6 -6 12 0 q6 -6 12 0" fill="none" stroke="#64748b" stroke-width="2"/><path d="M20 28 q6 -6 12 0 q6 -6 12 0" fill="none" stroke="#64748b" stroke-width="2"/><path d="M20 38 q6 -6 12 0 q6 -6 12 0" fill="none" stroke="#64748b" stroke-width="2"/><line x1="6" y1="6" x2="58" y2="58" stroke="#475569" stroke-width="3"/></svg>`)

// ════════════════════════════════════════════════════════════════
// ICONOS SWITCH (Conmutador/Hub)
// ════════════════════════════════════════════════════════════════

/**
 * Switch Sano: barra gris con 5 puertos verdes (conectados)
 * Simboliza: dispositivo de red funcional
 */
export const ICON_SWITCH = svgToDataUri(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect x="6" y="22" width="52" height="20" rx="2" fill="#334155" stroke="#94a3b8" stroke-width="2.5"/><rect x="12" y="28" width="5" height="5" fill="#22c55e"/><rect x="20" y="28" width="5" height="5" fill="#22c55e"/><rect x="28" y="28" width="5" height="5" fill="#22c55e"/><rect x="36" y="28" width="5" height="5" fill="#22c55e"/><rect x="44" y="28" width="5" height="5" fill="#22c55e"/></svg>`)

/**
 * Switch Infectado: barra roja con 5 puertos rojos
 * Simboliza: switch propagando malware a la red
 */
export const ICON_SWITCH_INFECTED = svgToDataUri(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect x="6" y="22" width="52" height="20" rx="2" fill="#451a1a" stroke="#ef4444" stroke-width="2.5"/><rect x="12" y="28" width="5" height="5" fill="#ef4444"/><rect x="20" y="28" width="5" height="5" fill="#ef4444"/><rect x="28" y="28" width="5" height="5" fill="#ef4444"/><rect x="36" y="28" width="5" height="5" fill="#ef4444"/><rect x="44" y="28" width="5" height="5" fill="#ef4444"/></svg>`)

/**
 * Switch Aislado: barra gris con puertos oscuros + tachada
 * Simboliza: switch fuera de servicio
 */
export const ICON_SWITCH_ISOLATED = svgToDataUri(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect x="6" y="22" width="52" height="20" rx="2" fill="#0f172a" stroke="#475569" stroke-width="2.5"/><rect x="12" y="28" width="5" height="5" fill="#334155"/><circle cx="44" cy="32" r="2" fill="#334155"/><line x1="6" y1="14" x2="58" y2="50" stroke="#475569" stroke-width="3"/></svg>`)

// ════════════════════════════════════════════════════════════════
// ICONOS CLOUD (Internet/Conexión Externa)
// ════════════════════════════════════════════════════════════════

/**
 * Cloud/Internet: nube amarilla (fuente original del ataque)
 * Nota: Internet SIEMPRE está infectado en la simulación (es el origen)
 */
export const ICON_CLOUD = svgToDataUri(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><path d="M18 40 a10 10 0 0 1 0 -20 a13 13 0 0 1 25 -4 a10 10 0 0 1 3 24 z" fill="#facc15" stroke="#854d0e" stroke-width="2"/></svg>`)

// ════════════════════════════════════════════════════════════════
// ICONOS SERVER (Servidor)
// ════════════════════════════════════════════════════════════════

/**
 * Server Sano: 3 cajas púrpuras con 3 luces verdes (operativo)
 * Simboliza: servidor funcionando, servicios activos
 */
export const ICON_SERVER = svgToDataUri(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect x="12" y="8" width="40" height="14" rx="2" fill="#581c87" stroke="#a855f7" stroke-width="2"/><rect x="12" y="25" width="40" height="14" rx="2" fill="#581c87" stroke="#a855f7" stroke-width="2"/><rect x="12" y="42" width="40" height="14" rx="2" fill="#581c87" stroke="#a855f7" stroke-width="2"/><circle cx="44" cy="15" r="2" fill="#22c55e"/><circle cx="44" cy="32" r="2" fill="#22c55e"/><circle cx="44" cy="49" r="2" fill="#22c55e"/></svg>`)

/**
 * Server Infectado: 3 cajas rojas con 3 luces rojas (apagado/comprometido)
 * Simboliza: servidor down o controlado por malware
 */
export const ICON_SERVER_INFECTED = svgToDataUri(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect x="12" y="8" width="40" height="14" rx="2" fill="#7f1d1d" stroke="#ef4444" stroke-width="2"/><rect x="12" y="25" width="40" height="14" rx="2" fill="#7f1d1d" stroke="#ef4444" stroke-width="2"/><rect x="12" y="42" width="40" height="14" rx="2" fill="#7f1d1d" stroke="#ef4444" stroke-width="2"/><circle cx="44" cy="15" r="2" fill="#ef4444"/><circle cx="44" cy="32" r="2" fill="#ef4444"/><circle cx="44" cy="49" r="2" fill="#ef4444"/></svg>`)

/**
 * Server Aislado: 3 cajas grises con línea diagonal
 * Simboliza: servidor offline (parcheo/mantenimiento)
 */
export const ICON_SERVER_ISOLATED = svgToDataUri(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect x="12" y="8" width="40" height="14" rx="2" fill="#0f172a" stroke="#475569" stroke-width="2"/><rect x="12" y="25" width="40" height="14" rx="2" fill="#0f172a" stroke="#475569" stroke-width="2"/><rect x="12" y="42" width="40" height="14" rx="2" fill="#0f172a" stroke="#475569" stroke-width="2"/><line x1="6" y1="4" x2="58" y2="60" stroke="#475569" stroke-width="3"/></svg>`)
