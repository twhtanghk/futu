<template>
  <v-container>
    <v-row><unlockAcc/></v-row>
    <v-row><tradeCreate :item='item'/></v-row>
    <v-row>
      <tradeFilled/>
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
import unlockAcc from './unlockAcc'
import tradeCreate from './tradeCreate'
import tradeFilled from './tradeFilled'
import {default as futu} from '../../../backend/futu'
{TrdSide} = futu

export default
  components: { 
    unlockAcc
    tradeCreate
    tradeFilled
  }
  data: ->
    item:
      trdSide: TrdSide.TrdSide_Buy
      code: '00700'
      qty: 1
</script>

<style lang='scss' scoped>
html, body {
  overflow: hidden;
}

.v-container .v-row:not(nth-child(3)) {
  height: 15vh;
  width: 100%;
}

.v-container .v-row:nth-child(3) {
  height: 70vh;
  width: 100%;
  overflow: auto;
}
</style>
