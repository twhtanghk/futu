<template>
  <v-container>
    <v-row no-gutters>
      <v-col><component :is='$route.params.view' initCode='800000'/></v-col>
      <v-col><component :is='$route.params.view' initCode='01211'/></v-col>
    </v-row>
    <v-row no-gutters>
      <v-col><component :is='$route.params.view' initCode='00388'/></v-col>
      <v-col><component :is='$route.params.view' initCode='00700'/></v-col>
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
import chart from './chart'
import option from './option'
import orderBook from './orderBook'

export default
  components:
    chart: chart
    option: option
    orderBook: orderBook
</script>
