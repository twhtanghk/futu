import { createApp } from 'vue'
import App from './App.vue'

import 'vuetify/styles'
import {createVuetify} from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import {md2} from 'vuetify/blueprints'
import * as VueRouter from 'vue-router'
import chart from './components/chart.vue'
import option from './components/option.vue'

const vuetify = createVuetify({components, directives, blueprint: md2})
const routes = [
  {path: '/', redirect: '/chart'},
  {path: '/chart', component: chart},
  {path: '/option', component: option}
]
const router = VueRouter.createRouter({
  history: VueRouter.createWebHashHistory(),
  routes
})

createApp(App)
  .use(vuetify)
  .use(router)
  .mount('#app')
