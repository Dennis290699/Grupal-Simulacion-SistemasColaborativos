<template>
  <div id="app-shell">
    <nav class="app-nav">
      <span class="app-nav-brand">BDI · GAMA</span>
      <div class="app-nav-links">
        <router-link to="/" class="nav-link">Simulación</router-link>
        <router-link to="/estadisticas" class="nav-link">Estadísticas</router-link>
      </div>
    </nav>
    <router-view />
  </div>
</template>

<script setup>
</script>

<style>
@import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600&family=Inter:wght@400;500;600&display=swap');

* { box-sizing: border-box; margin: 0; padding: 0; }
html, body, #app { background: #0a0f1e; }

.app-nav {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 24px;
  background: #0d1526;
  border-bottom: 1px solid #1e293b;
}
.app-nav-brand {
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  color: #f97316;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}
.app-nav-links { display: flex; gap: 8px; }
.nav-link {
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: #94a3b8;
  text-decoration: none;
  padding: 6px 14px;
  border-radius: 999px;
  transition: all 0.2s ease;
  border: 1px solid transparent;
}
.nav-link:hover { color: #e2e8f0; background: rgba(148, 163, 184, 0.08); }
.router-link-active { color: #f97316 !important; background: rgba(249, 115, 22, 0.12); border-color: rgba(249, 115, 22, 0.25); }
</style>
