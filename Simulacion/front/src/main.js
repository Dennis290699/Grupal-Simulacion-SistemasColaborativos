import { createApp } from 'vue'
import App from './App.vue'
import './style.css'
import VIcon from './components/VIcon.vue'
import router from './router'

const app = createApp(App)
app.use(router)
app.component('v-icon', VIcon)
app.mount('#app')
