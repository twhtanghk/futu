<template>
  <div class="chart" ref='curr'/>
</template>

<script lang='coffee'>
import {createChart} from 'lightweight-charts'
import mqtt from '../plugins/mqtt.coffee'

export default
  props:
    code:
      type: String
      default: '00700'
    chartOptions:
      type: Object
      default:
        layout:
          textColor: 'black'
          background:
            type: 'solid'
            color: 'white'
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
  data: ->
    chart: null
  methods:
    resize: ->
      {width, height} = @$refs.curr.getBoundingClientRect()
      @chart?.resize width, window.innerHeight
  mounted: ->
    window.addEventListener 'resize', =>
      @resize()
    @chart = createChart @$refs.curr, @chartOptions
    @chart.timeScale().applyOptions timeVisible: true
    series = @chart.addCandlestickSeries()
    mqtt
      .on 'message', (topic, msg) =>
        if topic == 'stock/candle/data'
          msg = JSON.parse msg.toString()
          {security, klList} = msg
          {market, code} = security
          if code == @code
            series.setData klList.map (i) ->
              i.time += 8 * 60 * 60 # adjust to HKT+8
              i
            @resize()
            @chart.timeScale().fitContent()
      .publish 'stock/candle', JSON.stringify code: @code
  unmounted: ->
    @chart?.remove()
    @chart = null
</script>

<style lang='scss' scoped>
.chart {
  height: auto;
}
</style>
