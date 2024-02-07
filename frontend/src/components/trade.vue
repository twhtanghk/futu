<template>
  <v-container>
    <v-row>
      <unlockAcc/>
    </v-row>
    <v-row>
      <tradeCreate :market='market' @update:market='market = $event'/>
    </v-row>
    <v-row>
      <tradeFilled :market='market'/>
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
import unlockAcc from './unlockAcc'
import tradeCreate from './tradeCreate'
import tradeFilled from './tradeFilled'

export default
  components: { 
    unlockAcc
    tradeCreate
    tradeFilled
  }
  data: ->
    market: 'hk'
</script>
