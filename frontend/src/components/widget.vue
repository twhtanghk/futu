<template>
  <v-container class='d-flex' style='height: 100%'>
    <v-row no-gutters style='height: 50vh'>
      <component
        v-for='i in codes'
        :is='$route.params.view'
        :initCode='i'
        @update:initCode='i = $event'
        :class='$vuetify.display.mdAndDown ? "col" : "col2"'
      />
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
import ohlcChart from './ohlcChart'
import chart from './chart'
import option from './option'
import orderBook from './orderBook'
import {parse} from 'cookie'

export default
  components:
    ohlcChart: ohlcChart
    chart: chart
    option: option
    orderBook: orderBook
  data: ->
    # array of [code, strikeDate, minPrice, maxPrice]
    codes: [
      ['800000', null, null, null]
      ['01211', null, null, null]
      ['00388', null, null, null]
      ['00700', null, null, null]
    ]
  beforeMount: ->
    cookie = parse document.cookie
    if 'codes' of cookie
      @codes = JSON.parse cookie.codes
  watch:
    codes:
      handler: (newCodes, oldCodes) -> 
        document.cookie = "codes=#{JSON.stringify newCodes}"
      deep: true
</script>

<style lang='scss' scoped>
.col2 {
  flex: 1 1 50%;
  height: 50%;
  width: 50%;
}

.col {
  flex: 1 1 100%;
  min-height: 300px;
  width: 100%;
}
</style>
