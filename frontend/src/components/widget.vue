<template>
  <v-container>
    <v-row no-gutters>
      <v-col>
        <component
          :is='$route.params.view'
          :initCode='codes[0]'
          @update:initCode='codes[0] = $event'
          :option='options[0]'
          @update:option='options[0] = $event'
        />
      </v-col>
      <v-col>
        <component
          :is='$route.params.view'
          :initCode='codes[1]'
          @update:initCode='codes[1] = $event'
          :option='options[1]'
          @update:option='options[1] = $event'
        />
      </v-col>
    </v-row>
    <v-row no-gutters>
      <v-col>
        <component
          :is='$route.params.view'
          :initCode='codes[2]'
          @update:initCode='codes[2] = $event'
          :option='options[2]'
          @update:option='options[2] = $event'
        />
      </v-col>
      <v-col>
        <component
          :is='$route.params.view'
          :initCode='codes[3]'
          @update:initCode='codes[3] = $event'
          :option='options[3]'
          @update:option='options[3] = $event'
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
    codes: [
      '800000'
      '01211'
      '00388'
      '00700'
    ]
    options: [
      []
      []
      []
      []
    ]
  beforeMount: ->
    cookie = parse document.cookie
    if 'codes' of cookie
      @codes = JSON.parse cookie.codes
    if 'options' of cookie
      @options = JSON.parse cookie.options
  watch:
    codes:
      handler: (newCodes, oldCodes) -> 
        document.cookie = "codes=#{JSON.stringify newCodes}"
      deep: true
    options:
      handler: (newOpts, oldOpts) ->
        document.cookie = "options=#{JSON.stringify newOpts}"
      deep: true
</script>
