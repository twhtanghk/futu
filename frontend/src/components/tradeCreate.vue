<template>
  <v-form>
    <v-container>
      <v-row>
        <v-col>{{ name }}</v-col>
        <v-col><v-select :items='sideList' v-model='side'/></v-col>
        <v-col><v-select :items='marketList' :value='market' @update:modelValue='$emit("update:market", $event)'/></v-col>
        <v-col><v-text-field v-model='code' @keyup.enter='getName'/></v-col>
        <v-col><v-text-field v-model='qty'/></v-col>
        <v-col><v-text-field v-model='price'/></v-col>
        <v-col><v-btn @click='create'>Create</v-btn></v-col>
      </v-row>
    </v-container>
  </v-form>
</template>

<script lang='coffee'>
api = require('../plugins/api').default
trade = require('../plugins/trade').default

export default
  props:
    market: String
  data: ->
    side: 'buy'
    code: '00700'
    qty: 100
    price: 0
    sideList: ['buy', 'sell']
    marketList: ['hk', 'crypto']
    name: null
  methods:
    getName: ->
      switch @market
        when 'hk'
          if @code?
            @name = await api.getName {@market, code: @code}
        when 'crypto'
          @name = @code
    create: ->
      await trade.create data: {@market, @code, @qty, @price}
  beforeMount: ->
    @getName()
</script>

<style lang='scss' scoped>
form {
  width: 100%;
}
</style>
