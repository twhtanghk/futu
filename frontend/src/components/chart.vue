<template>
  <v-container>
    <v-row algin='center'>
      <v-col>name</v-col>
      <v-col><v-select :items='intervalList' v-model='interval' filled/></v-col>
      <v-col><v-text-field v-model='code'/></v-col>
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
    code: '00700'
    interval: '1'
    intervalList: [
      '1'
      '5'
      '15'
      '30'
      '1h'
      '4h'
      '1d'
      '1w'
      '1m'
    ] 
  methods:
    resize: ->
      {width, height} = @$refs.curr.getBoundingClientRect()
      @chart?.resize width, window.innerHeight
  mounted: ->
    window.addEventListener 'resize', =>
      @resize()
    @chart = createChart @$refs.curr, @chartOptions
    @chart.timeScale().applyOptions timeVisible: true
    @chart.timeScale().subscribeVisibleTimeRangeChange (newRange) ->
      console.log JSON.stringify newRange
    series = @chart.addCandlestickSeries()
    mqtt
      .publish 'stock/candle', JSON.stringify code: @code
      .on 'message', (topic, msg) =>
        if topic == 'stock/candle/data'
          msg = JSON.parse msg.toString()
          {security, klList} = msg
          {market, code} = security
          if code == @code
            series.setData klList.map (i) ->
              i.time += 8 * 60 * 60 # adjust to HKT+8
              i
            @resize()
            @chart.timeScale().fitContent()
  unmounted: ->
    @chart?.remove()
    @chart = null
</script>

<style lang='scss' scoped>
.chart {
  height: auto;
}
</style>
