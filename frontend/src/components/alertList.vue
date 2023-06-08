<template>
  <v-data-table :headers='headers' :items='alert' density='compact' fixed-header='true' height='100%' items-per-page='-1'>
    <template v-slot:item.below='{ item }'>
      <span v-if='item.raw.edit'>
        <v-text-field type='number' @keyup.enter='update(item.raw)' v-model='item.raw.below'/>
      </span>
      <span @click='item.raw.edit=true' v-else :class='{red: item.raw.hitBelow}'>
        {{ item.raw.below }}
      </span>
    </template>
    <template v-slot:item.above='{ item }'>
      <span v-if='item.raw.edit'>
        <v-text-field type='number' @keyup.enter='update(item.raw)' v-model='item.raw.above'/>
      </span>
      <span @click='item.raw.edit=true' v-else :class='{green: item.raw.hitAbove}'>
        {{ item.raw.above}}
      </span>
    </template>
    <template v-slot:item.action='{ item }'>
      <v-btn density='compact' @click='cancel(item.raw.index)'>
        Delete
      </v-btn>
    </template>
  </v-data-table>
</template>

<script lang='coffee'>
import {default as ws} from '../plugins/ws'
{parse} = require 'cookie'
api = require('../plugins/api').default

export default
  data: ->
    headers: [
      {title: 'Name', key: 'name'}
      {title: 'Code', key: 'code'}
      {title: 'Below', key: 'below'}
      {title: 'Above', key: 'above'}
      {title: 'Action', key: 'action'}
    ]
    alert: []
    ws: null
  methods:
    read: ->
      ret = []
      cookie = parse document.cookie
      if 'alert' of cookie
        ret = JSON.parse cookie.alert
        for v, k in ret
          v.index = k
          v.name = await @getName v.code
          v.edit = false
      ret
    write: (alert) ->
      data = alert.map ({code, above, below}) ->
        {code, above, below}
      document.cookie = "alert=#{JSON.stringify data}"
    cancel: (index) ->
      @alert.splice index, 1
      @write @alert
    getName: (code) ->
      await api.getName code: code
    update: (row) ->
      row.edit = false
      @write @alert
  beforeMount: ->
    @ws = await ws
    @alert = await @read()
    for i in @alert
      @ws.subscribe
        code: i.code
        interval: '1'
    @ws.on 'message', ({topic, data}) =>
      for v, k in @alert
        if topic == 'candle' and 
           data.code == v.code
          if v.below > data.low
            @alert[k].hitBelow = true
          if data.high > v.above
            @alert[k].hitAbove = true
</script>

<style lang='scss' scoped>
.red {
  color: red;
}

.green {
  color: green;
}
</style>
