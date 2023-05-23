<template>
  <v-form>
    <v-container>
      <v-row>
        <v-col>{{ name }}</v-col>
        <v-col><v-text-field v-model='item.code' @keyup.enter='getName'/></v-col>
        <v-col><v-text-field v-model='item.below'/></v-col>
        <v-col><v-text-field v-model='item.above'/></v-col>
        <v-col><v-btn @click='create'>Create</v-btn></v-col>
      </v-row>
    </v-container>
  </v-form>
</template>

<script lang='coffee'>
import {default as futu} from '../../../backend/futu'
{QotMarket, TrdSide} = futu
api = require('../plugins/api').default
import {parse} from 'cookie'

export default
  props:
    item:
      type: Object # {code, below, above}
  data: ->
    name: null
  beforeMount: ->
    if @item.code?
      @getName()
  methods:
    getName: ->
      @name = await api.getName 
        market: QotMarket.QotMarket_HK_Security
        code: @item.code
    create: ->
      cookie = parse document.cookie
      alert = []
      if 'alert' of cookie
        alert = JSON.parse cookie.alert
      alert.push @item
      alert.sort (a, b) ->
        a.code - b.code
      document.cookie = "alert=#{JSON.stringify alert}"
</script>

<style lang='scss' scoped>
form {
  width: 100%;
}
</style>
