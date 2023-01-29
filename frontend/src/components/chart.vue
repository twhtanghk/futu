<template>
  <v-container>
    <v-row algin='center'>
      <v-col>{{ name }}</v-col>
      <v-col><v-select :items='intervalList' v-model='interval' filled/></v-col>
      <v-col><v-text-field v-model='code' @keyup.enter='setCode'/></v-col>
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
  methods:
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
          switch topic
            when 'stock/candle/data'
              msg = JSON.parse msg.toString()
              {security, klList} = msg
              {market, code} = security
              if code == @code
                @series.setData klList.map (i) ->
                  i.time += 8 * 60 * 60 # adjust to HKT+8
                  i
                @resize()
                @chart.timeScale().fitContent()
            when 'stock/name/data'
              res = JSON.parse msg.toString()
              if 'error' of res
                @name = res.error
              else
                [{security, name}, ...] = res
                if security.code == @code
                  @name = name
            when '1', '5', '15'
              if @interval == topic
                console.log JSON.parse msg.toString()
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
