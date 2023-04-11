<template>
  <v-form>
    <v-container>
      <v-row>
        <v-col><v-text-field v-model='passwd' :type='show ? "text" : "password"' :append-icon='show ? "mdi-eye" : "mdi-eye-off"' @click:append='show = ! show'/></v-col>
        <v-col><v-btn @click='unlock'>Unlock</v-btn></v-col>
      </v-row>
    </v-container>
  </v-form>
</template>

<script lang='coffee'>
md5 = require 'md5'
trade = require('../plugins/trade').default

export default
  data: ->
    passwd: null
  methods:
    unlock: ->
      await trade.update data: {id: 'unlock', pwdMD5: md5 @passwd}
</script>

<style lang='scss' scoped>
form {
  width: 100%;
}
</style>
