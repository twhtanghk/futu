<template>
  <v-container>
    <v-row><tradeCreate/></v-row>
    <v-row><tradeActive/></v-row>
    <v-row><tradeFilled/></v-row>
  </v-container>
</template>

<script lang='coffee'>
import tradeCreate from './tradeCreate.vue'
import tradeActive from './tradeActive.vue'
import tradeFilled from './tradeFilled.vue'

export default
  components: { 
    tradeCreate
    tradeActive
    tradeFilled
  }
</script>
