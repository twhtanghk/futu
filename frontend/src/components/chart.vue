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
    autosize:
      type: Boolean
      default: true
    chartOptions:
      type: Object
      default: {}
    seriesOptions:
      type: Object
      default:
        color: 'rgb(45, 77, 205)'
    timeScaleOptions:
      type: Object
      default: {}
    priceScaleOptions:
      type: Object
      default: {}
  mounted: ->
    chart = createChart @$refs.curr
    mqtt
      .on 'message', (topic, msg) =>
        if topic == 'stock/candle/data'
          msg = JSON.parse msg.toString()
          {security, klList} = msg
          {market, code} = security
          if code == @code
            series = chart.addCandlestickSeries()
            data = klList.map (i) ->
              {time, highPrice, lowPrice, openPrice, closePrice} = i
              time: time
              high: highPrice
              low: lowPrice
              open: openPrice
              close: closePrice
            console.log JSON.stringify data
            series.setData data
            chart.timeScale().fitContent()
      .publish 'stock/candle', JSON.stringify code: @code
  unmounted: ->
    chart?.remove()
    chart = null
</script>

<style lang='scss' scoped>
.chart {
  height: 100%;
}
</style>
