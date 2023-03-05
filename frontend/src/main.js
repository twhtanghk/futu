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

components.VDataTable = VDataTable
const vuetify = createVuetify({components, directives, blueprint: md2})
const routes = [
  {path: '/', redirect: '/widget/chart'},
  {path: '/widget/:view', component: widget},
  {path: '/position', component: position}
]
const router = VueRouter.createRouter({
  history: VueRouter.createWebHashHistory(),
  routes
})

createApp(App)
  .use(vuetify)
  .use(router)
  .mount('#app')
