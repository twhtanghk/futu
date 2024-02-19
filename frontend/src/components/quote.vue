<template>
  <v-container class='d-flex flex-wrap' sytle='height: 100%'>
    <div :class='$vuetify.display.mdAndDown ? "col" : "col2"'>
      <ohlcChart :initCode='[market == "hk" ? "800000" : "BTCUSDT", null, null, null]' style='height: 50vh'/>
      <ohlcChart :initCode='[$route.params.code, null, null, null]' style='height:50vh'/>
    </div>
    <div :class='$vuetify.display.mdAndDown ? "col" : "col2"'>
      <orderBook :initCode='$route.params.code'/>
      <opt v-if="market == 'hk'" :initCode='[$route.params.code, null, 290, 360]'/>
      <trade/>
    </div>
  </v-container>
</template>

<script lang='coffee'>
import ohlcChart from './ohlcChart'
import option from './option'
import orderBook from './orderBook'
import trade from './trade'

export default
  components:
    ohlcChart: ohlcChart
    opt: option
    orderBook: orderBook
    trade: trade
  data: ->
    market: @$route.params.market
</script>

<style lang='scss' scoped>
.col2 {
  flex: 1 1 50%;
  height: 50%;
  width: 50%;
}

.col {
  flex: 1 1 100%;
  min-height: 300px;
  width: 100%;
}
</style>
