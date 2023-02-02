<template>
  <v-container>
    <v-row>
      <v-col>{{ name }}</v-col>
      <v-col><v-select :items='marketList' item-title='text' item-value='value' v-model='market' filled/></v-col>
      <v-col><v-text-field v-model='code' @keyup.enter='setCode'/></v-col>
      <v-col><v-select :items='intervalList' v-model='interval' filled/></v-col>
    </v-row>
    <v-row>
      <v-col cols='18'>
        <div class='chart' ref='curr'/>
      </v-col>
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
import {createChart} from 'lightweight-charts'
import {default as futu} from '../../../backend/futu'
{Model} = require('model').default

api = new Model baseUrl: '/api'
#ws = new WebSocket 'ws://172.19.0.3:3000'
ws = new WebSocket "ws://#{location.host}"
ws.addEventListener 'error', console.error

export default
  props:
    chartOptions:
      type: Object
      default:
        layout:
          textColor: 'black'
          background:
            type: 'solid'
            color: 'white'
  data: ->
    chart: null
    series: null
    code: '00700'
    name: null
    interval: '1'
    intervalList: _.map futu.klType, (v, k) -> k
    market: futu.market['hkSecurity']
    marketList: [
      {text: 'HK Security', value: futu.market['hkSecurity']}
      {text: 'HK Future', value: futu.market['hkFuture']}
      {text: 'US Security', value: futu.market['usSecurity']}
      {text: 'CNSH Security', value: futu.market['cnshSecurity']}
      {text: 'CNSZ Security', value: futu.market['cnszSecurity']}
      {text: 'SG Security', value: futu.market['sgSecurity']}
      {text: 'JP Security', value: futu.market['jpSecurity']}
    ]
  methods:
    hktz: (time) ->
      time + 8 * 60 * 60 # adjust to HKT+8
    subscribe: ({code, interval} = {}) ->
      code ?= @code
      interval ?= @interval
      ws.send JSON.stringify
        action: 'subscribe'
        code: code
        interval: interval
    unsubscribe: ({code, interval} = {}) ->
      code ?= @code
      interval ?= @interval
      ws.send JSON.stringify
        action: 'unsubscribe'
        code: @code
        interval: interval
    setCode: (event) ->
      @getName()
      @getHistory()
    resize: ->
      {offsetWidth, offsetHeight} = @$refs.curr
      @chart?.resize offsetWidth, offsetHeight 
    getName: ->
      [{security, name}, ...] = await api.read 
        data:
          id: 'name'
          market: @market
          code: @code
      if security.code == @code
        @name = name
    getHistory: ->
      {security, klList} = await api.read 
        data: 
          id: 'candle'
          security:
            market: @market
            code: @code
          klType: futu.klType[@interval]
      {market, code} = security
      if code == @code
        @series.setData klList.map (i) =>
          i.time = @hktz i.time
          i
      @resize()
      @chart.timeScale().fitContent()
    parseRes: ->
      ws.addEventListener 'message', ({data}) =>
        {interval, quote} = JSON.parse data
        if interval == @interval and quote.code == @code
          quote.time = @hktz quote.timestamp
          @series.update quote
  mounted: ->
    window.addEventListener 'resize', =>
      @resize()
    @parseRes()
    @chart = createChart @$refs.curr, @chartOptions
    @series = @chart.addCandlestickSeries upColor: 'transparent'
    @chart.timeScale().applyOptions timeVisible: true
    @chart.timeScale().subscribeVisibleTimeRangeChange (newRange) ->
      console.log JSON.stringify newRange
    @setCode()
  unmounted: ->
    @chart?.remove()
    @chart = null
  watch:
    interval: (newVal, oldVal) ->
      @getHistory()
      @unsubscribe interval: oldVal
      @subscribe interval: newVal
</script>

<style lang='scss' scoped>
.chart {
  height: 30vh;
}
</style>
