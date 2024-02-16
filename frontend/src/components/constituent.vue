<template>
  <v-container>
    <v-row>
      <v-data-table :sort-by='sortBy' :headers='headers' :items='item' :items-per-page='-1' density='compact'>
        <template v-slot:item.code='{ item }'>
          <a :href="link(item.raw.code)" target='_blank'>
            {{ item.raw.code }}
          </a>
        </template>
        <template v-slot:item.time='{ item }'>
          {{ new Date(item.raw.time * 1000) }}
        </template>
      </v-data-table>
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
api = require('../plugins/api').default
ws = require('../plugins/ws').default
import {filter} from 'rxjs'

export default
  data: ->
    item: []
    sortBy: [{key: 'code', order: 'asc'}]
    headers: [
      {title: 'Code', key: 'code'}
      {title: 'Name', key: 'name'}
      {title: 'Delta', key: 'delta'}
      {title: 'Close', key: 'close'}
      {title: 'Close (mean)', key: 'close.mean'}
      {title: 'Close (stdev)', key: 'close.stdev'}
      {title: 'Close (trend)', key: 'close.trend'}
      {title: 'Volume', key: 'volume'}
      {title: 'Volume (mean)', key: 'volume.mean'}
      {title: 'Volume (stdev)', key: 'volume.stdev'}
      {title: 'Volume (trend)', key: 'volume.trend'}
      {title: 'Time', key: 'time'}
    ]
  methods:
    link: (code) ->
      "#/quote/hk/#{code}"
  mounted: ->
    (await ws)
      .constituent()
      .pipe filter ({topic, data}) ->
        topic == 'constituent'
      .subscribe ({topic, data}) =>
        @item.push 
          code: data.code
          name: data.name
          delta: ((data['close'] - data['close.mean']) / data['close.stdev'])
            .toFixed 2
          close: data['close'].toFixed 2
          'close.mean': data['close.mean'].toFixed 2
          'close.stdev': data['close.stdev'].toFixed 2
          'close.trend': data['close.trend']
          volume: data['volume']
          'volume.mean': data['volume.mean'].toFixed 2
          'volume.stdev': data['volume.stdev'].toFixed 2
          'volume.trend': data['volume.trend']
          time: data['timestamp']
</script>
