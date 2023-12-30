<template>
  <v-container class='d-flex flex-wrap' sytle='height: 100%'>
    <div :class='$vuetify.display.mdAndDown ? "col" : "col2"'>
      <chart :initCode='["800000", null, null, null]'/>
      <chart :initCode='[$route.params.code, null, null, null]'/>
    </div>
    <div :class='$vuetify.display.mdAndDown ? "col" : "col2"'>
      <orderBook :initCode='$route.params.code'/>
      <opt :initCode='[$route.params.code, null, 290, 360]'/>
      <trade/>
    </div>
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
    opt: option
    orderBook: orderBook
    trade: trade
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
