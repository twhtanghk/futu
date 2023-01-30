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
import mqtt from '../plugins/mqtt.coffee'
import futu from '../plugins/futu.coffee'

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
    intervalList: [
      '1'
      '5'
      '15'
      '30'
      '1h'
      '1d'
      '1w'
      '1m'
      '1y'
    ] 
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
      mqtt
        .publish 'stock/name', JSON.stringify [code: @code]
    getHistory: ->
      mqtt
        .publish 'stock/candle', JSON.stringify code: @code, interval: @interval
    parseRes: ->
      mqtt
        .on 'message', (topic, msg) =>
          msg = JSON.parse msg.toString()
          switch topic
            when 'stock/candle/data'
              {security, klList} = msg
              {market, code} = security
              if code == @code
                @series.setData klList.map (i) =>
                  i.time = @hktz i.time
                  i
                @resize()
                @chart.timeScale().fitContent()
            when 'stock/name/data'
              if 'error' of msg
                @name = res.error
              else
                [{security, name}, ...] = msg
                if security.code == @code
                  @name = name
            when 'stock/realtime'
              {interval, quote} = msg
              if interval == @interval and quote.symbol == @code
                quote.time = @hktz quote.lastUpdatedAt
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
      mqtt.publish 'stock/unsubscribe', JSON.stringify {code: @code, interval: oldVal}
      mqtt.publish 'stock/subscribe', JSON.stringify {code: @code, interval: newVal}
</script>

<style lang='scss' scoped>
.chart {
  height: auto;
}
</style>
