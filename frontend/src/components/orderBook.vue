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
import {default as Futu} from '../../../index'

export default
  props:
    initCode:
      type: String
      default:
        '00700'
  data: ->
    api: require('../plugins/api').default
    ws: null
    code: null
    name: null
    market: 'hk'
    curr: null # last subscribed market and code
    ask: []
    bid: []
  methods:
    setCode: (event) ->
      @name = await @api.getName {market: 'hk', code: @code}
      document.title = "#{@code} #{@name}"
      @subscribe()
    subscribe: ->
      if @curr?
        @ws.orderBook
          market: 'hk'
          code: @curr.code
      @curr = {@market, @code}
      @ws.orderBook
        market: 'hk'
        code: @code
  beforeMount: ->
    @ws = (await ws)
      .on 'message', (msg) =>
        {topic, data} = msg
        {market, code, ask, bid} = data
        if topic == 'orderBook' and market == @market and code == @code
          @ask = ask
          @bid = bid
    @code = @initCode
    @setCode()
</script>
