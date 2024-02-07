<template>
  <v-container>
    <v-row>
      <v-col>
        <v-text-field v-model='passwd' :type='show ? "text" : "password"' :append-inner-icon='show ? "fa-solid fa-eye" : "fa-solid fa-eye-slash"' @click:append-inner='show = ! show'/>
      </v-col>
      <v-col>
        <v-btn @click='unlock'>Unlock</v-btn>
      </v-col>
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
md5 = require 'md5'
trade = require('../plugins/trade').default

export default
  data: ->
    passwd: null
    show: false
  methods:
    unlock: ->
      await trade.update data: {id: 'unlock', pwdMD5: md5 @passwd}
</script>
