<template>
  <v-container>
    <v-row>
      <v-col>{{ name }}</v-col>
      <v-col><v-text-field density='compact' v-model='$route.params.code'/></v-col>
      <v-col><v-select density='compact' :items='intervalList' v-model='interval'/></v-col>
    </v-row>
    <v-row no-gutters>
      <v-col cols='18'>
        <div class='chart' ref='curr'/>
      </v-col>
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
import moment from 'moment'
import {default as ws} from '../plugins/ws'
import {createChart, LineStyle} from 'lightweight-charts'
import Futu from '../../../index'
import {volSML} from '../plugins/lib'
{Model} = require('model').default

export default
  props:
    freq:
      type: String
    chartOptions:
      type: Object
      default:
        layout:
          textColor: 'black'
          background:
            type: 'solid'
            color: 'white'
  data: ->
    api: require('../plugins/api').default
    ws: null
    chart: null
    series:
      candle: null
      volatility: null
      volume: null
    code: null
    name: null
    interval: '1'
    intervalList: _.map Futu.subTypeMap, (v, k) -> k
  methods:
    color: ({open, close}) ->
      if open > close then 'red' else 'green' 
    hktz: (time) ->
      time + 8 * 60 * 60 # adjust to HKT+8
    ohlc: ->
      @ws.ohlc
        market: 'hk'
        code: @$route.params.code
        interval: @interval
    resize: ->
      {offsetWidth, offsetHeight} = @$refs.curr
      @chart?.resize offsetWidth, offsetHeight 
    clear: ->
      @series.candle.setData []
      @series.volatility.setData []
      @series.volume.setData []
  beforeMount: ->
    @ws = await ws
    @ws.on 'message', ({topic, data}) =>
      if topic == 'ohlc' and data.code == @$route.params.code
        data.time = @hktz data.timestamp
        @series.candle.update data
        @series.volume.update
          time: data.time
          value: data.volume
          color: @color data
  mounted: ->
    flag = false
    window.addEventListener 'resize', =>
      @resize()
    @chart = createChart @$refs.curr, @chartOptions
    @series.candle = @chart.addCandlestickSeries upColor: 'transparent'
    @series.volatility = @chart.addLineSeries 
      color: 'blue'
      lineWidth: 1
      priceFormat:
        type: 'price'
      priceScaleId: 'volatility'
    @series.volume = @chart.addHistogramSeries
      color: 'blue'
      priceFormat:
        type: 'volume'
      priceScaleId: 'volume'
      scaleMargins:
        top: 0.7
        bottom: 0
    @chart.timeScale().applyOptions timeVisible: true
    @chart.timeScale().subscribeVisibleTimeRangeChange =>
      if flag
        return
      flag = true
      logicalRange = @chart.timeScale().getVisibleLogicalRange()
      barsInfo = @series.candle.barsInLogicalRange logicalRange
  unmounted: ->
    @chart?.remove()
    @chart = null
  watch:
    interval: (newVal, oldVal) ->
      @clear()
      @ohlc()
</script>

<style lang='scss' scoped>
.chart {
  height: 90vh;
}
</style>
