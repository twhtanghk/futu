<template>
  <v-container>
    <v-row>
      <v-data-table :sort-by='sortBy' :headers='headers' :items='item' :items-per-page='-1' density='compact'>
        <template v-slot:item.code='{ item }'>
          <a :href="link(item.raw.code)" target='_blank'>
            {{ item.raw.code }}
          </a>
        </template>
        <template v-slot:item.close='{ item }'>
          {{ item.raw.close.toFixed(2) }}
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
      "#/quote/#{code}"
  mounted: ->
    (await ws)
      .constituent()
      .on 'message', (msg) =>
        {topic, data} = msg
        if topic == 'constituent'
          data.map ({code, last}) =>
            @item.push 
              code: code
              name: await api.getName {code}
              delta: (last['close'] - last['close.mean']) / last['close.stdev']
              close: last['close']
              'close.mean': last['close.mean']
              'close.stdev': last['close.stdev']
              'close.trend': last['close.trend']
              volume: last['volume']
              'volume.mean': last['volume.mean']
              'volume.stdev': last['volume.stdev']
              'volume.trend': last['volume.trend']
              time: last['time']
</script>
