import { createApp } from 'vue'
import App from './App.vue'

import 'vuetify/styles'
import {createVuetify} from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import {md2} from 'vuetify/blueprints'

const vuetify = createVuetify({components, directives, blueprint: md2})

createApp(App).use(vuetify).mount('#app')
