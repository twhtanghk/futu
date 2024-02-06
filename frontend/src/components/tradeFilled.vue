<template>
  <v-data-table :sort-by='sortBy' :headers='headers' :items='orderList' density='compact' fixed-header='true' height='100%' items-per-page='-1'>
    <template v-slot:item.trdSide='{ item }'>
      <v-chip :color="item.raw.side == 'sell' ? 'green' : 'red'">
        {{trdSide(item.raw.side)}}
      </v-chip>
    </template>
    <template v-slot:item.id='{ item }'>
      {{item.raw.id}}
    </template>
    <template v-slot:item.status='{ item }'>
      {{status(item.raw.status)}}
    </template>
    <template v-slot:item.type='{ item }'>
      {{type(item.raw.type)}}
    </template>
    <template v-slot:item.qty='{ item }'>
      {{item.raw.fillQty}} / {{item.raw.qty}}
    </template>
    <template v-slot:item.price='{ item }'>
      {{item.raw.price.toFixed(2)}}
    </template>
    <template v-slot:item.createTime='{ item }'>
      {{new Date(1000 * item.raw.createTime).toLocaleString()}}
    </template>
    <template v-slot:item.updateTime='{ item }'>
      {{new Date(1000 * item.raw.updateTime).toLocaleString()}}
    </template>
    <template v-slot:item.action='{ item }'>
      <v-btn density='compact' @click='cancel(item.raw)'>
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
import moment from 'moment'
import {default as ws} from '../plugins/ws'
import {filter, map} from 'rxjs'
api = require('../plugins/api').default
trade = require('../plugins/trade').default
{Order} = require('algotrader/rxData').default

export default
  data: ->
    market: 'hk'
    sortBy: [{key: 'updateTimestamp', order: 'desc'}]
    headers: [
      {title: 'Order ID', key: 'id'}
      {title: 'Side', key: 'side'}
      {title: 'Status', key: 'status'}
      {title: 'Type', key: 'type'}
      {title: 'Code', key: 'code'}
      {title: 'Name', key: 'name'}
      {title: 'Qty', key: 'qty'}
      {title: 'Price', key: 'price'}
      {title: 'Created at', key: 'createTime'}
      {title: 'Updated at', key: 'updateTime'}
      {title: 'Action', key: 'action'}
    ]
    orderList: []
  methods:
    status: (x) ->
      x
    type: (x) ->
      x
    cancel: ({orderID}) ->
      await trade.delete data: id: orderID
  mounted: ->
    ws
      .subMarket {@market}
      .pipe filter ({topic, data}) ->
        topic in ['orderList', 'orderCreate', 'orderUpdate', 'orderDelete']
      .pipe map ({topic, data}) =>
        switch topic
          when 'orderList'
            @orderList.push new Order data
          when 'orderCreate'
            @orderList.push new Order data
          when 'orderUpdate', 'orderDelete'
            console.log 'update order'
      .subscribe (x) -> return
</script>
