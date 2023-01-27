<template>
  <div class="chart" ref='curr'/>
</template>

<script lang='coffee'>
import {createChart} from 'lightweight-charts'
import mqtt from '../plugins/mqtt.coffee'

chart = null
      
export default
  props:
    code:
      type: String
      default: '00700'
    data:
      type: Array
    autosize:
      type: Boolean
      default: true
    chartOptions:
      type: Object
    seriesOptions:
      type: Object
    timeScaleOptions:
      type: Object
    priceScaleOptions:
      type: Object
  mounted: ->
    chart = createChart @$refs.curr
    mqtt.publish 'stock/candle', JSON.stringify code: @code
    futu = await new Futu host: 'localhost', port: 33333
    {security, klList} = await futu.historyKL
      market: QotMarket.QotMarket_HK_Security
      code: '00700'
    @data = klList
  unmounted: ->
    chart?.remove()
    chart = null

mqtt.on 'message', (topic, msg) ->
  if topic == 'stock/candle'
    msg = JSON.parse msg.toString()
    {security, klList} = msg
    {market, code} = security
</script>

<style lang='scss' scoped>
.chart {
  height: 100%;
}
</style>
