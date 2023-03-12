<template>
  <v-data-table :sort-by='sortBy' :headers='headers' :items='deal' :items-per-page='-1' density='compact'>
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
      {title: 'Filled Qty', key: 'fillQty'}
      {title: 'Filled Avg Price', key: 'fillAvgPrice'}
      {title: 'Created at', key: 'createTimestamp'}
      {title: 'Updated at', key: 'updateTimestamp'}
    ]
    trade: []
  mounted: ->
    @ws = (await ws)
      .subscribeAcc()
      .on 'message', (msg) =>
        {topic, data} = msg
        {orderFill} = data
        if topic == 'trdFilled'
          @deal.push _.pick orderFill, [
            'trdSide'
            'code'
            'name'
            'qty'
            'price'
            'fillQty'
            'fillAvgPrice'
            'createTimestamp'
            'updateTimestamp'
          ]
    @trade = (await trade.list())
</script>
