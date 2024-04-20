<template>
  <v-container class='d-flex flex-column' style='height:100%'>
    <v-tooltip activator='parent' location='top' v-if='meanBar != null'>
      Mean({{code}}, high - low): {{meanBar[0]}}, {{meanBar[1]}}%
    </v-tooltip>
    <v-row class='flex-grow-0'>
      <v-col>
        <v-select density='compact' :items="strategyList" v-model="selectedStrategy" multiple/>
        <v-dialog v-model='dialog' width='auto' transition='dailog-top-transition'>
          <v-card :title='currStrategy'>
            <template v-slot:title>
              <v-select density='compact' :items="strategyList" v-model="currStrategy"/>
            </template>
            <v-card-text>
              <v-container>
                <v-row v-if="currStrategy.match(/^grid.*/)">
                  <v-col cols='12'>
                    <v-text-field label='low' required v-model.number='settings[currStrategy].low' type='number'/>
                  </v-col>
                  <v-col cols='12'>
                    <v-text-field label='high' required v-model.number='settings[currStrategy].high' type='number'/>
                  </v-col>
                  <v-col cols='12'>
                    <v-text-field label='grid size' required v-model.number='settings[currStrategy].gridSize' type='number'/>
                  </v-col>
                </v-row>
                <v-row v-if="currStrategy == 'meanReversion'">
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
      <v-col>
        <v-icon @click='dialog = true' icon='fas fa-gear'/>
        <v-icon @click='tradeEnable = true' v-if='!tradeEnable' icon='fas fa-lock'/>
        <v-icon @click='tradeEnable = false' v-if='tradeEnable' icon='fas fa-lock-open'/>
      </v-col>
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
{freqDuration} = require('algotrader/rxData').default
import {default as strategy} from 'algotrader/rxStrategy'
import {default as generator} from 'generator'
import {uniqBy} from 'lodash'
{meanBar, skipDup} = require('algotrader/analysis').default.ohlc
trade = require('../plugins/trade').default

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
      levels:
        arr: null
      meanReversion:
        chunkSize: 60
        n: 2
        plRatio: [0.01, 0.005]
      gridRange:
        low: 0
        high: 0
        gridSize: 3
        stopLoss: 0.005
      gridTrend:
        low: 0
        high: 0
        gridSize: 3
        stopLoss: 0.005
      pinBar:
        percent: 70
      insideBar:
        null
      volUp:
        n: 2
    api: require('../plugins/api').default
    selectedStrategy: ['meanReversion']
    currStrategy: 'levels'
    strategyList: ['levels', 'gridRange', 'gridTrend', 'meanReversion', 'levelVol', 'priceVol', 'pinBar', 'insideBar', 'volUp']
    market: @$route.params.market || 'hk'
    chart: null
    series:
      candle: null
      volatility: null
      stdevSq: null
      volume: null
    code: @initCode?[0] || @$route.params.code
    name: null
    freq: '5'
    intervalList: _.map Futu.klTypeMap, (v, k) -> k
    subscription: null
    lastOpts: null
    meanBar: null
    tradeEnable: false
  methods:
    color: ({open, close}) ->
      if open > close then 'red' else 'green' 
    hktz: (time) ->
      time + 8 * 60 * 60 # adjust to HKT+8
    # request for ohlc data
    ohlc: ->
      if @lastOpts?
        @unsubKL @lastOpts
      @lastOpts = {@market, @code, @freq}
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
      @series.stdevSq.setData []
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
      @settings.levels.arr = (await @api.level {market: @market, code: @code})
        .map (level, i) =>
          @series.candle.createPriceLine
            color: 'red'
            lineWidth: 1
            lineStyle: LineStyle.Dashed
            price: level
            axisLabelVisible: true
            title: "#{level}"
          level
      @resize()
    # draw candle stick chart
    redraw: ->
      markers = []
      @subscription = (await @ohlc())
        .pipe tap (i) =>
          @series.candle.update i
          @series.volume.update
            time: i.time
            value: i.volume
            color: @color i
        # skip duplicate
        .pipe skipDup()
        .pipe meanBar()
        .pipe strategy.indicator()
        # use selected strategy to show entryExit markers
        .pipe (obs) =>
          ret = obs
          for s in @selectedStrategy
            ret = (strategy[s] @settings[s]) ret
          ret
        .subscribe (i) =>
          @series.volatility.update
            time: i.time
            value: i['close.stdev']
          @series.stdevSq.update
            time: i.time
            value: i['close.stdev.stdev']
          @meanBar = i.meanBar
          if 'entryExit' of i
            text = i.entryExit.map (entry) ->
              obj = {}
              obj[entry.strategy] = entry.side
              obj
            side = i.entryExit[0]?.side
            markers.push
              time: i.time
              position: if side == 'buy' then 'belowBar' else 'aboveBar'
              color: if side == 'buy' then 'blue' else 'red'
              shape: if side == 'buy' then 'arrowUp' else 'arrowDown'
              text: JSON.stringify text
            @series.candle.setMarkers markers
            if @tradeEnable
              await trade.create data: {@market, @code, side, plPrice, qty: 1, price: (i.high + i.low) / 2}
  beforeMount: ->
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
    @series.stdevSq = @chart.addLineSeries 
      color: 'red'
      lineWidth: 1
      priceFormat:
        type: 'price'
      priceScaleId: 'stdevSq'
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
      @subscription?.unsubscribe()
      @clear()
      await @redraw()
    selectedStrategy: (newVal, oldVal) ->
      @subscription?.unsubscribe()
      @clear()
      await @redraw()
</script>
