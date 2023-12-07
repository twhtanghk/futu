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
    intervalList: _.map Futu.klTypeMap, (v, k) -> k
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
    unsubscribe: (interval) ->
      @ws.unsubscribe
        market: 'hk'
        code: @$route.params.code
        interval: interval
    resize: ->
      {offsetWidth, offsetHeight} = @$refs.curr
      @chart?.resize offsetWidth, offsetHeight 
    clear: ->
      @series.candle.setData []
      @series.volatility.setData []
      @series.volume.setData []
    getHistory:  ({beginTime, endTime} = {}) ->
      if beginTime?
        beginTime = beginTime
          .format 'YYYY-MM-DD'
      if endTime?
        endTime = endTime
          .format 'YYYY-MM-DD'
      {security, klList} = await @api.getHistory
        security:
          market: Futu.marketMap['hk']
          code: @$route.params.code
        klType: Futu.klTypeMap[@interval]
        beginTime: beginTime
        endTime: endTime
      {market, code} = security
      if code == @$route.params.code
        data = klList
          .map (i) =>
            i.time = @hktz i.time
            i
          .concat @series.candle.data()
        @series.candle.setData data
        volData = klList
          .map ({time, volume, open, close}) =>
            time: time
            value: volume
            color: @color {open, close}
          .concat @series.volume.data()
        @series.volume.setData volData
        (await @api.level {code: @$route.params.code})
          .map (level, i) =>
            @series.candle.createPriceLine
              color: 'red'
              lineWidth: 1
              lineStyle: LineStyle.Dashed
              price: level
              axisLabelVisible: true
              title: "#{level}"
      @resize()
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
    @ohlc()
  mounted: ->
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
      priceFormat:
        type: 'volume'
      priceScaleId: 'volume'
    @series.volume.priceScale().applyOptions
      scaleMargins:
        top: 0.7
        bottom: 0
    @chart.timeScale().applyOptions timeVisible: true
    calling = false
    @chart.timeScale().subscribeVisibleTimeRangeChange =>
      if calling
        return
      calling = true
      try
        barsInfo = @series.candle
          .barsInLogicalRange @chart.timeScale().getVisibleLogicalRange()
        if barsInfo?.barsBefore < 10
          [first, ...] = @series.candle.data()
          await @getHistory
            beginTime: moment.unix(first.time).subtract 3, 'month'
            endTime: moment.unix(first.time).subtract 1, 'day'
      finally
        calling = false
  unmounted: ->
    @chart?.remove()
    @chart = null
  watch:
    interval: (newVal, oldVal) ->
      @clear()
      @unsubscribe oldVal
      @ohlc()
</script>

<style lang='scss' scoped>
.chart {
  height: 90vh;
}
</style>
