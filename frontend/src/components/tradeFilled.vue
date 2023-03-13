<template>
  <v-data-table :sort-by='sortBy' :headers='headers' :items='trade' :items-per-page='-1' density='compact' fixed-header='true' height='100%'>
    <template v-slot:item.trdSide='{ item }'>
      <v-chip :color="item.raw.trdSide == 2 ? 'green' : 'red'">
        {{trdSide(item.raw.trdSide)}}
      </v-chip>
    </template>
    <template v-slot:item.orderStatus='{ item }'>
      {{orderStatus(item.raw.orderStatus)}}
    </template>
    <template v-slot:item.qty='{ item }'>
      {{item.raw.fillQty}} / {{item.raw.qty}}
    </template>
    <template v-slot:item.price='{ item }'>
      {{item.raw.fillAvgPrice.toFixed(2)}} / {{item.raw.price.toFixed(2)}}
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
      {title: 'Status', key: 'orderStatus'}
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
    trdSide: (i) ->
      ['Unknown', 'Buy', 'Sell', 'SellShort', 'Buyback'][i]
    orderStatus: (i) ->
      map = {
        '-1': 'Unknown'
        0: 'Unsubmitted'
        1: 'WaitingSubmit'
        2: 'Submitting'
        3: 'SubmitFailed'
        4: 'Timeout'
        5: 'Submitted'
        10: 'Filled_Part'
        11: 'Filled_All'
        12: 'Cancelling_Part'
        13: 'Cancelling_All'
        14: 'Cancelled_Part'
        15: 'Cancelled_All'
        21: 'Failed'
        22: 'Disabled'
        23: 'Deleted'
        24: 'FillCancelled'
      }
      map[i]
  mounted: ->
    @ws = (await ws)
      .on 'message', (msg) =>
        {topic, data} = msg
        {orderFill} = data
        if topic == 'trdFilled'
          @trade.push _.pick orderFill, [
            'trdSide'
            'orderStatus'
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
