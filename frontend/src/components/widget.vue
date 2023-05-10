<template>
  <v-container>
    <v-row no-gutters>
      <v-col>
        <component
          :is='$route.params.view'
          :initCode='codes[0]'
          @update:initCode='codes[0] = $event'
        />
      </v-col>
      <v-col>
        <component
          :is='$route.params.view'
          :initCode='codes[1]'
          @update:initCode='codes[1] = $event'
        />
      </v-col>
    </v-row>
    <v-row no-gutters>
      <v-col>
        <component
          :is='$route.params.view'
          :initCode='codes[2]'
          @update:initCode='codes[2] = $event'
        />
      </v-col>
      <v-col>
        <component
          :is='$route.params.view'
          :initCode='codes[3]'
          @update:initCode='codes[3] = $event'
        />
      </v-col>
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
import chart from './chart'
import option from './option'
import orderBook from './orderBook'
import {parse} from 'cookie'

export default
  components:
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
