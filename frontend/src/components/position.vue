<template>
  <v-data-table :sort-by='sortBy' :headers='headers' :items='position'/>
</template>

<script lang='coffee'>
import {default as api} from '../plugins/api'
import {default as futu} from '../../../backend/futu'

export default
  data: ->
    api: require('../plugins/api').default
    market: futu.QotMarket.QotMarket_HK_Security
    sortBy: [{key: 'val', order: 'desc'}]
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
  mounted: ->
    @position = (await @api.getPosition())
</script>
