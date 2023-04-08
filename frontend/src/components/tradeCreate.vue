<template>
  <v-form>
    <v-container>
      <v-row>
        <v-col>{{ name }}</v-col>
        <v-col><v-select :items='trdSideList' item-title='text' item-value='value' v-model='item.trdSide'/></v-col>
        <v-col><v-text-field v-model='item.code' @keyup.enter='getName'/></v-col>
        <v-col><v-text-field v-model='item.qty'/></v-col>
        <v-col><v-text-field v-model='item.price'/></v-col>
        <v-col><v-btn @click='create'>Create</v-btn></v-col>
      </v-row>
    </v-container>
  </v-form>
</template>

<script lang='coffee'>
import {default as futu} from '../../../backend/futu'
{QotMarket, TrdSide} = futu
api = require('../plugins/api').default
trade = require('../plugins/trade').default

export default
  props:
    item:
      type: Object # {trdSide, code, qty, price}
      default:
        trdSide: TrdSide.TrdSide_Buy
        code: null
        qty: null
        price: null
  data: ->
    trdSideList: [
      {text: 'Buy', value: TrdSide.TrdSide_Buy}
      {text: 'Sell', value: TrdSide.TrdSide_Sell}
      {text: 'SellShort', value: TrdSide.TrdSide_SellShort}
      {text: 'BuyBack', value: TrdSide.TrdSide_BuyBack}
    ]
    market: QotMarket.QotMarket_HK_Security
    name: null
  methods:
    getName: ->
      @name = await api.getName {@market, code: @item.code}
    create: ->
      await trade.create data: @item
  beforeMount: ->
    @getName()
</script>

<style lang='scss' scoped>
form {
  width: 100%;
}
</style>
