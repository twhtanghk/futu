<template>
  <v-container>
    <v-row algin='center'>
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
ws = new WebSocket 'ws://172.19.0.3:3000/quote'
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
    setCode: (event) ->
      @getName()
      @getHistory()
    resize: ->
      {width, height} = @$refs.curr.getBoundingClientRect()
      @chart?.resize width, window.innerHeight
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
      ws.onmessage = ({data}) =>
        {interval, quote} = JSON.parse data
        if interval == @interval and quote.code == @code
          quote.time = @hktz quote.timestamp
          @series.update quote
  mounted: ->
    window.addEventListener 'resize', =>
      @resize()
    @parseRes()
    @chart = createChart @$refs.curr, @chartOptions
    @chart.timeScale().applyOptions timeVisible: true
    @chart.timeScale().subscribeVisibleTimeRangeChange (newRange) ->
      console.log JSON.stringify newRange
    @series = @chart.addCandlestickSeries()
    @setCode()
  unmounted: ->
    @chart?.remove()
    @chart = null
  watch:
    interval: (newVal, oldVal) ->
      @getHistory()
      ws.send JSON.stringify
        action: 'unsubscribe'
        code: @code
        interval: oldVal
      ws.send JSON.stringify
        action: 'subscribe'
        code: @code
        interval: newVal
</script>

<style lang='scss' scoped>
.chart {
  height: auto;
}
</style>
