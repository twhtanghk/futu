<template>
  <v-container>
    <v-row v-if='add'>
      <tradeCreate :item='addData'/>
    </v-row>
    <v-row>
  <v-data-table :sort-by='sortBy' :headers='headers' :items='position' :items-per-page='-1' density='compact'>
    <template v-slot:column.plVal='{ column }'>
      <v-chip :color="plSum() > 0 ? 'green' : 'red'">
        {{ column.title }} {{ plSum() }}
      </v-chip>
    </template>
    <template v-slot:item.plVal='{ item }'>
      <v-chip :color="item.raw.plVal > 0 ? 'green' : 'red'">
        {{ item.raw.plVal }}
      </v-chip>
    </template>
    <template v-slot:item.action='{ item }'>
      <v-btn class='mr-md-2' variant='outlined' color='red' @click='buy(item.raw)'>Buy</v-btn>
      <v-btn variant='outlined' color='green' @click='sell(item.raw)'>Sell</v-btn>
    </template>
  </v-data-table>
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
import {default as api} from '../plugins/api'
import {default as futu} from '../../../backend/futu'
import tradeCreate from './tradeCreate'
{TrdSide} = futu

export default
  components: {tradeCreate}
  data: ->
    api: require('../plugins/api').default
    market: futu.QotMarket.QotMarket_HK_Security
    sortBy: [{key: 'name', order: 'desc'}]
    headers: [
      {title: 'Code', key: 'code'}
      {title: 'Name', key: 'name'}
      {title: 'Qty', key: 'qty'}
      {title: 'Price', key: 'price'}
      {title: 'Cost', key: 'costPrice'}
      {title: 'Value', key: 'val'}
      {title: 'P&L', key: 'plVal'}
      {title: 'P&L Ratio', key: 'plRatio'}
      {title: 'Action', key: 'action'}
    ]
    position: []
    add: false
    addData: null
  methods: 
    plSum: ->
      ret = 0
      for i in @position
        ret += i.plVal
      ret
    sell: (item) ->
      @add = true
      @addData = 
        trdSide: TrdSide.TrdSide_Sell
        code: item.code
        qty: item.qty
    buy: (item) ->
      @add = true
      @addData = 
        trdSide: TrdSide.TrdSide_Buy
        code: item.code
        qty: item.qty
  mounted: ->
    @position = (await @api.getPosition())
</script>
