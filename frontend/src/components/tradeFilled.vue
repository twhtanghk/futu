<template>
  <v-data-table :sort-by='sortBy' :headers='headers' :items='trade' density='compact' fixed-header='true' height='100%' items-per-page='-1'>
    <template v-slot:item.trdSide='{ item }'>
      <v-chip :color="item.raw.trdSide == 2 ? 'green' : 'red'">
        {{trdSide(item.raw.trdSide)}}
      </v-chip>
    </template>
    <template v-slot:item.orderID='{ item }'>
      {{item.raw.orderID}}
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
    <template v-slot:item.action='{ item }'>
      <v-btn density='compact' @click='cancel(item.raw)'
        v-if='! isFilled(item.raw)'
      >
        Cancel
      </v-btn>
    </template>
    <template v-slot:bottom>
      <div id='intersect' v-intersect='onShow'>
        Loading... Please wait
      </div>
    </template>
  </v-data-table>
</template>

<script lang='coffee'>
moment = require 'moment'
ws = require('../plugins/ws').default
api = require('../plugins/api').default
trade = require('../plugins/trade').default
import Futu from '../../../index'
{QotMarket, OrderStatus} = Futu.constant

export default
  data: ->
    market: QotMarket.QotMarket_HK_Security
    sortBy: [{key: 'updateTimestamp', order: 'desc'}]
    headers: [
      {title: 'Order ID', key: 'orderID'}
      {title: 'Trade', key: 'trdSide'}
      {title: 'Status', key: 'orderStatus'}
      {title: 'Code', key: 'code'}
      {title: 'Name', key: 'name'}
      {title: 'Qty', key: 'qty'}
      {title: 'Price', key: 'price'}
      {title: 'Created at', key: 'createTimestamp'}
      {title: 'Updated at', key: 'updateTimestamp'}
      {title: 'Action', key: 'action'}
    ]
    trade: []
  methods:
    nextPage: ->
      [..., last] = @trade
      endTime = null
      if last?
        endTime = moment
          .unix last.createTimestamp
          .format 'YYYY-MM-DD HH:mm:ss'
      @trade = @trade.concat await trade.list data: {endTime}
    trdSide: (i) ->
      ['Unknown', 'Buy', 'Sell', 'SellShort', 'Buyback'][i]
    isFilled: ({orderStatus}) ->
      orderStatus not in [
        OrderStatus.OrderStatus_Filled_Part
        OrderStatus.OrderStatus_Submitted
        OrderStatus.OrderStatus_WaitingSubmit
        OrderStatus.OrderStatus_Submitting
      ]
    cancel: ({orderID}) ->
      await trade.delete data: id: orderID
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
    onShow: (isIntersecting, entries, observer) ->
      if isIntersecting
        await @nextPage()
  mounted: ->
    @ws = (await ws)
      .subscribeAcc()
      .on 'message', (msg) =>
        {topic, data} = msg
        if topic == 'trdUpdate'
          @trade.shift data
          @trade = _.uniqBy @trade, 'orderID'
</script>
