<template>
  <v-container>
    <v-row><unlockAcc/></v-row>
    <v-row><tradeCreate/></v-row>
    <v-row>
      <tradeFilled/>
      <div v-intersect='onShow'/>
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
import unlockAcc from './unlockAcc'
import tradeCreate from './tradeCreate'
import tradeFilled from './tradeFilled'

export default
  components: { 
    unlockAcc
    tradeCreate
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

.v-container .v-row:not(nth-child(3)) {
  height: 15vh;
  width: 100%;
}

.v-container .v-row:nth-child(3) {
  height: 70vh;
  width: 100%;
  overflow: auto;
}
</style>
