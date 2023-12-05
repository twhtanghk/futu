<template>
  <v-container>
    <v-row><alertCreate :item='item'/></v-row>
    <v-row>
      <alertList/>
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
import alertCreate from './alertCreate'
import alertList from './alertList'
import {default as Futu} from '../../../index'
{TrdSide} = Futu.constant

export default
  components: { 
    alertCreate
    alertList
  }
  data: ->
    item:
      code: '00700'
      above: null
      below: null
</script>
