<template>
  <v-container class='d-flex flex-column' style='height:100%'>
    <v-row class='flex-grow-0'>
      <v-col>
        <v-select density='compact' :items="['gridTrend', 'meanReversion', 'levelVol', 'priceVol']" v-model="selectedStrategy" append-icon='fa-solid fa-gear' @click:append='dialog = true'/>
        <v-dialog v-model='dialog' width='auto' transition='dailog-top-transition'>
          <v-card :title='title()'>
            <v-card-text>
              <v-container>
                <v-row v-if="selectedStrategy == 'gridTrend'">
                  <v-col cols='12'>
                    <v-text-field label='low' required v-model.number='settings.gridTrend.low' type='number'/>
                  </v-col>
                  <v-col cols='12'>
                    <v-text-field label='high' required v-model.number='settings.gridTrend.high' type='number'/>
                  </v-col>
                  <v-col cols='12'>
                    <v-text-field label='grid size' required v-model.number='settings.gridTrend.gridSize' type='number'/>
                  </v-col>
                </v-row>
                <v-row v-if="selectedStrategy == 'meanReversion'">
                  <v-col cols='12'>
                    <v-text-field label='chunk size' required v-model.number='settings.meanReversion.chunkSize' type='number'/>
                  </v-col>
                  <v-col cols='12'>
                    <v-text-field label='n (stdev)' required v-model.number='settings.meanReversion.n' type='number'/>
                  </v-col>
                  <v-col cols='12'>
                    <v-text-field label='profit ratio' required v-model.number='settings.meanReversion.plRatio[0]' type='number'/>
                  </v-col>
                  <v-col cols='12'>
                    <v-text-field label='loss ratio' required v-model.number='settings.meanReversion.plRatio[1]' type='number'/>
                  </v-col>
                </v-row>
              </v-container>
            </v-card-text>
            <v-card-actions>
              <v-btn color="primary" block @click="dialog = false">Close</v-btn>
            </v-card-actions>
          </v-card>
        </v-dialog>
      </v-col>
      <v-col>
        <v-select density='compact' :items="['hk', 'crypto']" v-model="selectedMarket"/>
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
{freqDuration} = require('algotrader/data').default
import {default as strategy} from 'algotrader/strategy'
import {default as generator} from 'generator'
import fromEmitter from '@async-generators/from-emitter'
import {uniqBy} from 'lodash'

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
    dialog: false
    settings:
      meanReversion:
        chunkSize: 60
        n: 2
        plRatio: [0.01, 0.005]
      gridTrend:
        low: 0
        high: 0
        gridSize: 3
        stopLoss: 0.005
    api: require('../plugins/api').default
    selectedStrategy: 'meanReversion'
    selectedMarket: 'hk'
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
    title: ->
      switch @selectedStrategy 
        when 'meanReversion' 
          @selectedStrategy
        when 'gridTrend'
          {low, high, gridSize, stopLoss} = @settings.gridTrend
          "#{@selectedStrategy} #{i for i in [low..high] by (high - low) / gridSize}" 
    color: ({open, close}) ->
      if open > close then 'red' else 'green' 
    hktz: (time) ->
      time + 8 * 60 * 60 # adjust to HKT+8
    # request for ohlc data
    ohlc: ->
      @ws = await ws
      @ws.ohlc
        market: @selectedMarket
        code: @code
        interval: @interval
    # create generator to keep watch for socket if message emitted
    getData: ->
      socket = @ws
      df = ->
        fromEmitter socket, onNext: 'message'
      # parse websocket message into {topic, data}
      parsed = generator.map df, (i) ->
        JSON.parse i.data
      # filter those targeted market, code, and freq only
      code = ({topic, data}) =>
        topic == 'ohlc' and
        data.market == @selectedMarket and
        data.code == @code and
        data.freq == @interval
      # get ohlc data only
      ohlc = ({topic, data}) ->
        data.time = data.timestamp
        data
      generator.map (generator.filter parsed, code), ohlc
    unsubscribe: (interval) ->
      @ws.unsubscribe
        market: @selectedMarket
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
      klList = await @api.history
        market: @selectedMarket
        code: @code
        start: beginTime
        end: endTime
        freq: @interval
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
      (await @api.level {market: @selectedMarket, code: @code})
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
      s = (df) =>
        strategy[@selectedStrategy] df, @settings[@selectedStrategy]
      do =>
        for await i from s strategy.indicator generator.uniqBy g, 'timestamp'
          if 'entryExit' of i
            {side, plPrice} = i.entryExit
            markers.push
              time: @hktz i.time
              position: if side == 'buy' then 'belowBar' else 'aboveBar'
              color: if side == 'buy' then 'blue' else 'red'
              shape: if side == 'buy' then 'arrowUp' else 'arrowDown'
              text: "#{i.entryExit.strategy} #{side} #{plPrice}"
            @series.candle.setMarkers uniqBy markers, 'time'
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
            beginTime: 
              moment
                .unix first.time - 8 * 60 * 60
                .subtract freqDuration[@interval].dataFetched
            endTime:
              moment
                .unix first.time - 8 * 60 * 60
                .subtract freqDuration[@interval].duration
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
</script>
