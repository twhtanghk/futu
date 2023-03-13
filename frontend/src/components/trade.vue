<template>
  <v-container>
    <v-row><tradeCreate/></v-row>
    <v-row><tradeActive/></v-row>
    <v-row>
      <tradeFilled/>
      <div v-intersect='onShow'/>
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
import tradeCreate from './tradeCreate.vue'
import tradeActive from './tradeActive.vue'
import tradeFilled from './tradeFilled.vue'

export default
  components: { 
    tradeCreate
    tradeActive
    tradeFilled
  }
  methods:
    onShow: (isIntersecting, entries, observer) ->
      if isIntersecting
        @emitter.emit 'scrollEnd'
</script>

<style lang='scss' scoped>
html, body {
  overflow: hidden;
}

.v-container .v-row:nth-child(1) {
  height: 20vh;
  width: 100%;
}

.v-container .v-row:nth-child(2) {
  height: 30vh;
  width: 100%;
}

.v-container .v-row:nth-child(3) {
  height: 50vh;
  width: 100%;
  overflow: auto;
}
</style>
