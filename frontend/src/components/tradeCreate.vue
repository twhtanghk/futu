<template>
  <v-form>
    <v-container>
      <v-row>
        <v-col><v-text-field v-model='passwd' :type='show ? "text" : "password"' :append-icon='show ? "mdi-eye" : "mdi-eye-off"' @click:append='show = ! show'/></v-col>
        <v-col><v-btn @click='unlock'>Unlock</v-btn></v-col>
      </v-row>
      <v-row>
        <v-col>{{ name }}</v-col>
        <v-col><v-select :items='trdSideList' item-title='text' item-value='value' v-model='trdSide'/></v-col>
        <v-col><v-text-field v-model='code' @keyup.enter='getName'/></v-col>
        <v-col><v-text-field v-model='qty'/></v-col>
        <v-col><v-text-field v-model='price'/></v-col>
        <v-col><v-btn @click='create'>Create</v-btn></v-col>
      </v-row>
    </v-container>
  </v-form>
</template>

<script lang='coffee'>
{QotMarket, TrdSide} = require('../../../backend/futu').default
api = require('../plugins/api').default
trade = require('../plugins/trade').default
md5 = require 'md5'

export default
  data: ->
    trdSide: TrdSide.TrdSide_Buy
    trdSideList: [
      {text: 'Buy', value: TrdSide.TrdSide_Buy}
      {text: 'Sell', value: TrdSide.TrdSide_Sell}
      {text: 'SellShort', value: TrdSide.TrdSide_SellShort}
      {text: 'BuyBack', value: TrdSide.TrdSide_BuyBack}
    ]
    market: QotMarket.QotMarket_HK_Security
    passwd: null
    show: false
    code: null
    name: null
    qty: 0
    price: null
  methods:
    getName: ->
      @name = await api.getName {@market, @code}
    create: ->
      await trade.create data: {@trdSide, @code, @qty, @price}
    unlock: ->
      await trade.update data: {id: 'unlock', pwdMD5: md5 @passwd}
</script>

<style lang='scss' scoped>
form {
  width: 100%;
}
</style>
