<template>
  <v-container>
    <v-row no-gutters>{{code}}</v-row>
    <v-row no-gutters>
      <v-col>
        <v-row no-gutters>bid</v-row>
        <v-row v-for='i in bid' no-gutters>
          <v-col>{{i.price}}</v-col>
          <v-col>{{i.volume}}</v-col>
          <v-col>{{i.orederCount}}</v-col>
        </v-row>
      </v-col>
      <v-col>
        <v-row no-gutters>ask</v-row>
        <v-row v-for='i in ask' no-gutters>
          <v-col>{{i.price}}</v-col>
          <v-col>{{i.volume}}</v-col>
          <v-col>{{i.orederCount}}</v-col>
        </v-row>
      </v-col>
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
import {default as ws} from '../plugins/ws'
import {default as api} from '../plugins/api'
import {default as Futu} from 'rxfutu'
import {filter} from 'rxjs'

export default
  props:
    code:
      type: String
      default:
        '00700'
  data: ->
    market: 'hk'
    ask: []
    bid: []
    active: false
  methods: 
    unsubscribe: ->
      (await ws).unsubscribe
        subtype: Futu.constant.SubType.SubType_OrderBook
        market: @market
        code: @code
  mounted: ->
    ws
      .orderBook {@market, @code}
      .pipe filter ({topic, data}) =>
        {market, code} = data
        topic == 'orderBook' and
        market == @market and
        code == @code
      .subscribe ({topic, data}) =>
        {market, code, ask, bid} = data
        @ask = ask
        @bid = bid
  unmounted: ->
    @unsubscribe()
</script>
