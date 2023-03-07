<template>
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
  </v-data-table>
</template>

<script lang='coffee'>
import {default as api} from '../plugins/api'
import {default as futu} from '../../../backend/futu'

export default
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
    ]
    position: []
  methods: 
    plSum: ->
      ret = 0
      for i in @position
        ret += i.plVal
      ret
  mounted: ->
    @position = (await @api.getPosition())
</script>
