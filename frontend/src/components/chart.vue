<template>
  <v-container>
    <v-row>
      <v-col>{{ name }}</v-col>
      <v-col><v-text-field density='compact' v-model='code' @keyup.enter='setCode'/></v-col>
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
    initCode:
      type: Array
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
    candles: []
    nodata: false
    chart: null
    series:
      candle: null
      volatility: null
      volume: null
    code: null
    name: null
    interval: '1'
    intervalList: _.map Futu.klTypeMap, (v, k) -> k
    market: Futu.constant.QotMarket.QotMarket_HK_Security
    marketList: require('../plugins/const').default.marketList
  methods:
    clear: ->
      @candles = []
      @nodata = false
    color: ({open, close}) ->
      if open > close then 'red' else 'green' 
    hktz: (time) ->
      time + 8 * 60 * 60 # adjust to HKT+8
    subscribe: ({market, code, interval} = {}) ->
      market ?= @market
      code ?= @code
      interval ?= @interval
      @ws.subscribe
        market: market
        code: code
        interval: interval
    unsubscribe: ({market, code, interval} = {}) ->
      market ?= @market
      code ?= @code
      interval ?= @interval
      @ws.unsubscribe
        market: market
        code: code
        interval: interval
    setCode: (event) ->
      @clear()
      @name = await @api.getName {@market, @code}
      await @getHistory()
      @subscribe()
      @$emit 'update:initCode', [@code, @initCode[1..]...]
    resize: ->
      {offsetWidth, offsetHeight} = @$refs.curr
      @chart?.resize offsetWidth, offsetHeight 
    getHistory: ({beginTime, endTime} = {}) ->
      if beginTime?
        beginTime = beginTime
          .format 'YYYY-MM-DD'
      if endTime?
        endTime = endTime
          .format 'YYYY-MM-DD'
      {security, klList} = await @api.getHistory
        security:
          market: @market
          code: @code
        klType: Futu.klTypeMap[@interval]
        beginTime: beginTime
        endTime: endTime
      {market, code} = security
      if code == @code
        data = klList.map (i) =>
          i.time = @hktz i.time
          i
        @nodata = klList.length == 0
        @candles = [data..., @candles...]
        volSML @candles, 20, 20, 20
        [..., last] = @candles
        @series.candle.setData @candles
        @series.volatility.setData @candles.map ({time, volatility}) ->
          time: time
          value: volatility.s
        @series.volume.setData @candles.map ({time, volume, open, close}) =>
          time: time
          value: volume
          color: @color {open, close}
        (await @api.level {@code})
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
      if topic == 'candle' and data.code == @code
        data.time = @hktz data.timestamp
        @series.candle.update data
        @series.volume.update
          time: data.time
          value: data.volume
          color: @color data
    @code = @initCode[0]
    @setCode()
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
      [first, ..., last] = @candles
      if barsInfo?.barsBefore < 10
        endTime = moment
          .unix first.time
          .subtract days: 1
        diff = switch @interval
          when '1', '5', '15', '30', '1h'
            days: 10
          when '1d'
            month: 1
          when '1w'
            month: 6
          when '1m'
            year: 1
          when '1y'
            year: 20
        beginTime = moment endTime.valueOf()
          .subtract diff
        if not @nodata
          await @getHistory {beginTime, endTime}
      flag = false
  unmounted: ->
    @chart?.remove()
    @chart = null
  watch:
    interval: (newVal, oldVal) ->
      @clear()
      @getHistory()
      @unsubscribe interval: oldVal
      @subscribe interval: newVal
</script>

<style lang='scss' scoped>
.chart {
  height: 40vh;
}
</style>
