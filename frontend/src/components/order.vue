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
import {default as futu} from '../../../backend/futu'

export default
  props:
    code:
      type: String
      default:
        '00700'
  data: ->
    market: futu.QotMarket.QotMarket_HK_Security
    ask: []
    bid: []
    active: false
  methods: 
    subscribe: ->
      (await ws).subscribe
        subtype: futu.SubType.SubType_OrderBook
        market: @market
        code: @code
    unsubscribe: ->
      (await ws).unsubscribe
        subtype: futu.SubType.SubType_OrderBook
        market: @market
        code: @code
  mounted: ->
    @subscribe()
    (await ws)
      .on 'message', (msg) =>
        {topic, data} = msg
        {market, code, orderBookAskList, orderBookBidList} = data
        if topic == 'orderBook' and market == @market and code == @code
          @ask = orderBookAskList
          @bid = orderBookBidList
  unmounted: ->
    @unsubscribe()
</script>
