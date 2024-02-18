import { createApp } from 'vue'
import App from './App.vue'

import 'vuetify/styles'
import '@fortawesome/fontawesome-free/css/all.css'
import {createVuetify} from 'vuetify'
import {aliases, fa} from 'vuetify/iconsets/fa'
import {VDataTable} from 'vuetify/labs/VDataTable'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import {md2} from 'vuetify/blueprints'
import * as VueRouter from 'vue-router'
import widget from './components/widget.vue'
import position from './components/position.vue'
import trade from './components/trade.vue'
import alert from './components/alert.vue'
import quote from './components/quote.vue'
import ohlcChart from './components/ohlcChart.vue'
import constituent from './components/constituent.vue'

components.VDataTable = VDataTable
const vuetify = createVuetify({
  components,
  directives,
  blueprint: md2,
  icons: {
    defaultSet: 'fa',
    aliases,
    sets: {fa}
  }
})
const routes = [
  {path: '/', redirect: '/widget/ohlcChart'},
  {path: '/widget/:view', component: widget},
  {path: '/position', component: position},
  {path: '/trade/:market/:code', component: trade},
  {path: '/alert', component: alert},
  {path: '/quote/:market/:code', component: quote},
  {path: '/ohlc/:market/:code', component: ohlcChart},
  {path: '/constituent', component: constituent}
]
const router = VueRouter.createRouter({
  history: VueRouter.createWebHashHistory(),
  routes
})

const app = createApp(App)
app
  .use(vuetify)
  .use(router)
  .mount('#app')
