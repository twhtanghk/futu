<template>
  <v-container class='d-flex flex-column'>
    <v-row class='flex-grow-0'>
      <v-col>
        <v-select density='compact' :items="['meanReversion', 'levelVol', 'priceVol']" v-model="selectedStrategy"/>
      </v-col>
      <v-col><v-text-field density='compact' v-model='code' @keyup.enter='clear(); ohlc(); redraw();'/></v-col>
      <v-col><v-select density='compact' :items='intervalList' v-model='interval'/></v-col>
    </v-row>
    <v-row no-gutters class='flex-grow-1'>
      <v-col>
        <div style='height: 100%' ref='curr'/>
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
import {default as strategy} from 'algotrader/strategy'
import {default as generator} from 'generator'
import fromEmitter from '@async-generators/from-emitter'

export default
  props:
    initCode:
      type: Array
    chartOptions:
      type: Object
      default:
        autoSize: true
        layout:
          textColor: 'black'
          background:
            type: 'solid'
            color: 'white'
  data: ->
    api: require('../plugins/api').default
    selectedStrategy: 'levelVol'
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
    # request for ohlc data
    ohlc: ->
      @ws = await ws
      @ws.ohlc
        market: 'hk'
        code: @code
        interval: @interval
    # create generator to keep watch for socket if message emitted
    getData: ->
      socket = @ws
      df = ->
        for await i from fromEmitter socket, onNext: 'message'
          {topic, data} = JSON.parse i.data
          yield {topic, data}
      # filter those targeted code only
      code = ({topic, data}) =>
        topic == 'ohlc' and data.code == @code
      # get ohlc data only
      ohlc = ({topic, data}) ->
        data
      generator.map (generator.filter df, code), ohlc
    unsubscribe: (interval) ->
      @ws.unsubscribe
        market: 'hk'
        code: @code
        interval: interval
    resize: ->
      {offsetWidth, offsetHeight} = @$refs.curr
      @chart?.resize offsetWidth, offsetHeight 
    clear: ->
      @series.candle.setData []
      @series.candle.setMarkers []
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
          code: @code
        klType: Futu.klTypeMap[@interval]
        beginTime: beginTime
        endTime: endTime
      {market, code} = security
      if code == @code
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
        (await @api.level {code: @code})
          .map (level, i) =>
            @series.candle.createPriceLine
              color: 'red'
              lineWidth: 1
              lineStyle: LineStyle.Dashed
              price: level
              axisLabelVisible: true
              title: "#{level}"
      @resize()
    # draw candle stick chart
    redraw: ->
      g = @getData()
      do =>
        for await i from g()
          i.time = @hktz i.timestamp
          @series.candle.update i
          @series.volume.update
            time: i.time
            value: i.volume
            color: @color i
      @redrawMarker()
    # use selected strategy to show entryExit markers
    redrawMarker: ->
      markers = []
      g = @getData()
      s = strategy[@selectedStrategy]
      do =>
        for await i from s strategy.indicator g
          if 'entryExit' of i
            {side, plPrice} = i.entryExit
            markers.push
              time: i.time
              position: if side == 'buy' then 'belowBar' else 'aboveBar'
              color: if side == 'buy' then 'blue' else 'red'
              shape: if side == 'buy' then 'arrowUp' else 'arrowDown'
              text: "#{side} #{plPrice}"
            @series.candle.setMarkers markers
  beforeMount: ->
    @code = @initCode?[0] || @$route.params.code
    await @ohlc()
    @redraw()
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
      await @ohlc()
      @redraw()
    selectedStrategy: (newVal, oldVal) ->
      @clear()
      await @ohlc()
      @redraw()
</script>
