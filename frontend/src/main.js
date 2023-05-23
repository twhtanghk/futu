import { createApp } from 'vue'
import App from './App.vue'

import 'vuetify/styles'
import {createVuetify} from 'vuetify'
import {VDataTable} from 'vuetify/labs/VDataTable'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import {md2} from 'vuetify/blueprints'
import * as VueRouter from 'vue-router'
import widget from './components/widget.vue'
import position from './components/position.vue'
import deal from './components/deal.vue'
import trade from './components/trade.vue'
import alert from './components/alert.vue'
import '@mdi/font/css/materialdesignicons.css'

components.VDataTable = VDataTable
const vuetify = createVuetify({components, directives, blueprint: md2})
const routes = [
  {path: '/', redirect: '/widget/chart'},
  {path: '/widget/:view', component: widget},
  {path: '/position', component: position},
  {path: '/deal', component: deal},
  {path: '/trade', component: trade},
  {path: '/alert', component: alert}
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
