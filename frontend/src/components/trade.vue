<template>
  <v-container>
    <v-row style='height: 15vh, width: 100%'>
      <unlockAcc/>
    </v-row>
    <v-row style='height: 15vh, width: 100%'>
      <tradeCreate :item='item'/>
    </v-row>
    <v-row style='height: 70vh, width: 100%, overflow: auto'>
      <!--tradeFilled/-->
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
</style>
