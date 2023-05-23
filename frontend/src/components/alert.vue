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
import {default as futu} from '../../../backend/futu'
{TrdSide} = futu

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
