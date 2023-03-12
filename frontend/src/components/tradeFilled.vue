<template>
  <v-data-table :sort-by='sortBy' :headers='headers' :items='trade' :items-per-page='-1' density='compact' fixed-header='true' height='100%'>
    <template v-slot:item.trdSide='{ item }'>
      <v-chip :color="item.raw.trdSide == 2 ? 'green' : 'red'">
        {{ item.raw.trdSide == 2 ? 'Sell' : 'Buy'}}
      </v-chip>
    </template>
    <template v-slot:item.createTimestamp='{ item }'>
      {{new Date(1000 * item.raw.createTimestamp).toLocaleString()}}
    </template>
    <template v-slot:item.updateTimestamp='{ item }'>
      {{new Date(1000 * item.raw.updateTimestamp).toLocaleString()}}
    </template>
  </v-data-table>
</template>

<script lang='coffee'>
moment = require 'moment'
ws = require('../plugins/ws').default
api = require('../plugins/api').default
trade = require('../plugins/trade').default
{QotMarket} = require('../../../backend/futu').default

export default
  data: ->
    market: QotMarket.QotMarket_HK_Security
    sortBy: [{key: 'updateTimestamp', order: 'desc'}]
    headers: [
      {title: 'Action', key: 'trdSide'}
      {title: 'Code', key: 'code'}
      {title: 'Name', key: 'name'}
      {title: 'Qty', key: 'qty'}
      {title: 'Price', key: 'price'}
      {title: 'Created at', key: 'createTimestamp'}
      {title: 'Updated at', key: 'updateTimestamp'}
    ]
    trade: []
  methods:
    nextPage: ->
      [..., last] = @trade
      endTime = null
      if last?
        endTime = moment
          .unix last.updateTimestamp
          .format 'YYYY-MM-DD HH:mm:ss'
      @trade = @trade.concat await trade.list {endTime}
  mounted: ->
    @ws = (await ws)
      .on 'message', (msg) =>
        {topic, data} = msg
        {orderFill} = data
        if topic == 'trdFilled'
          @trade.push _.pick orderFill, [
            'trdSide'
            'code'
            'name'
            'qty'
            'price'
            'createTimestamp'
            'updateTimestamp'
          ]
  beforeMount: ->
    @emitter.on 'scrollEnd', =>
      @nextPage()
</script>
