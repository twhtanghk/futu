<template>
  <v-container>
    <v-row no-gutters>
      <v-col>
        <v-row>
          <chart :initCode='["800000", null, null, null]'/>
        </v-row>
        <v-row>
          <chart :initCode='[$route.params.code, null, null, null]'/>
        </v-row>
      </v-col>
      <v-col>
        <v-row>
          <v-col>
            <orderBook/>
          </v-col>
          <v-col>
            <orderBook/>
          </v-col>
        </v-row>
        <v-row>
          <option/>
        </v-row>
        <v-row>
          <trade/>
        </v-row>
      </v-col>
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
import chart from './chart'
import option from './option'
import orderBook from './orderBook'
import trade from './trade'

export default
  components:
    chart: chart
    option: option
    orderBook: orderBook
    trade: trade
  data: ->
  beforeMount: ->
</script>
