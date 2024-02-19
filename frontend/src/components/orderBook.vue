<template>
  <v-container>
    <v-row>
      <v-col>{{ name }}</v-col>
      <v-col><v-text-field density='compact' v-model='code' @keyup.enter='setCode'/></v-col>
    </v-row>
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
import {filter, map} from 'rxjs'
import {default as Futu} from 'rxfutu'

export default
  props:
    initCode:
      type: String
      default:
        '00700'
  data: ->
    api: require('../plugins/api').default
    code: @$route.params.code
    name: null
    market: @$route.params.market
    curr: null # last subscribed market and code
    ask: []
    bid: []
  methods:
    setCode: (event) ->
      @name = switch @market
        when 'hk'
          await @api.getName {@market, @code}
        when 'crypto'
          @code
      document.title = "#{@code} #{@name}"
      @subscribe()
    subscribe: ->
      if @curr?
        ws.orderBook {@market, @code}
      @curr = {@market, @code}
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
  mounted: ->
    @setCode()
  unmounted: ->
    ws.unsubOrderBook {@market, @code}
</script>
