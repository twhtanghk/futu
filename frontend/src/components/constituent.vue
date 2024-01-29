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
      .subscribe (msg) =>
        {topic, data} = msg
        if topic == 'constituent'
          @item.push 
            code: data.code
            name: await api.getName {code: data.code}
            delta: (data['close'] - data['close.mean']) / data['close.stdev']
            close: data['close']
            'close.mean': data['close.mean']
            'close.stdev': data['close.stdev']
            'close.trend': data['close.trend']
            volume: data['volume']
            'volume.mean': data['volume.mean']
            'volume.stdev': data['volume.stdev']
            'volume.trend': data['volume.trend']
            time: data['timestamp']
</script>
