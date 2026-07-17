import { createRouter, createWebHistory } from 'vue-router'
import Dashboard from '../views/Dashboard.vue'
import Estadisticas from '../views/Estadisticas.vue'

const routes = [
  { path: '/', name: 'dashboard', component: Dashboard },
  { path: '/estadisticas', name: 'estadisticas', component: Estadisticas },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
