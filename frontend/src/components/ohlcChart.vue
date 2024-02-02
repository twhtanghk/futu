<template>
  <v-container class='d-flex flex-column' style='height:100%'>
    <v-tooltip activator='parent' location='top' v-if='meanBar != null'>
      Mean({{code}}, high - low): {{meanBar[0]}}, {{meanBar[1]}}%
    </v-tooltip>
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
        <v-select density='compact' :items="['hk', 'crypto']" v-model="market"/>
      </v-col>
      <v-col><v-text-field density='compact' v-model='code' @keyup.enter='clear(); redraw();'/></v-col>
      <v-col><v-select density='compact' :items='intervalList' v-model='freq'/></v-col>
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
import {bufferCount, tap, filter, map} from 'rxjs'
import Futu from 'rxfutu'
{Model} = require('model').default
{freqDuration} = require('algotrader/data').default
import {default as strategy} from 'algotrader/rxStrategy'
import {default as generator} from 'generator'
import fromEmitter from '@async-generators/from-emitter'
import {uniqBy} from 'lodash'
{meanBar} = require('algotrader/analysis').default.ohlc

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
    market: 'hk'
    chart: null
    series:
      candle: null
      volatility: null
      volume: null
    code: null
    name: null
    freq: '1'
    intervalList: _.map Futu.klTypeMap, (v, k) -> k
    lastOpts: null
    meanBar: null
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
      if lastOpts?
        @unsubKL lastOpts
      lastOpts = {@market, @code, @freq}
      ws
        .ohlc
          market: @market
          code: @code
          freq: @freq
        .pipe filter ({topic, data}) =>
          {market, code, freq} = data
          topic == 'ohlc' and
          market == @market and
          code == @code and
          freq == @freq
        .pipe map ({topic, data}) =>
          data.time = @hktz data.timestamp
          data
        .pipe meanBar()
        .pipe strategy.indicator()
    unsubKL: ({market, code, freq}) ->
      ws.unsubKL
        market: market
        code: code
        freq: freq
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
        market: @market
        code: @code
        start: beginTime
        end: endTime
        freq: @freq
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
      (await @api.level {market: @market, code: @code})
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
      markers = []
      (await @ohlc())
        .pipe tap (i) =>
          @series.candle.update i
          @series.volume.update
            time: i.time
            value: i.volume
            color: @color i
        # remove duplicate and use selected strategy to show entryExit markers
        .pipe bufferCount 2, 1
        .pipe filter ([prev, curr]) ->
          prev.time != curr.time
        .pipe map ([prev, curr]) ->
          prev
        .pipe strategy[@selectedStrategy] @settings[@selectedStrategy]
        .subscribe (i) =>
          @meanBar = i.meanBar
          if 'entryExit' of i
            {side, plPrice} = i.entryExit
            markers.push
              time: i.time
              position: if side == 'buy' then 'belowBar' else 'aboveBar'
              color: if side == 'buy' then 'blue' else 'red'
              shape: if side == 'buy' then 'arrowUp' else 'arrowDown'
              text: "#{i.entryExit.strategy} #{side} #{plPrice}"
            @series.candle.setMarkers markers
  beforeMount: ->
    @code = @initCode?[0] || @$route.params.code
    @redraw()
  mounted: ->
    window.addEventListener 'resize', =>
      @resize()
    @chart = createChart @$refs.curr, @chartOptions
    @series.candle = @chart.addCandlestickSeries upColor: 'transparent'
    @series.candle.priceScale().applyOptions
      scaleMargins:
        top: 0
        bottom: 0.3
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
                .subtract freqDuration[@freq].dataFetched
            endTime:
              moment
                .unix first.time - 8 * 60 * 60
                .subtract freqDuration[@freq].duration
      finally
        calling = false
  unmounted: ->
    @unsubKL {@market, @code, @freq}
    @chart?.remove()
    @chart = null
  watch:
    freq: (newVal, oldVal) ->
      @clear()
      await @redraw()
    selectedStrategy: (newVal, oldVal) ->
      @clear()
      await @redraw()
</script>
