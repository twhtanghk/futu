<template>
  <v-container>
    <v-row>
      <v-col>{{ name }}</v-col>
      <v-col><v-select density='compact' :items='marketList' item-title='text' item-value='value' v-model='market'/></v-col>
      <v-col><v-text-field density='compact' v-model='code' @keyup.enter='setCode'/></v-col>
      <v-col><v-text-field density='compact' v-model.number='min'/></v-col>
      <v-col><v-text-field density='compact' v-model.number='max'/></v-col>
    </v-row>
    <v-row no-gutters>
      <v-col v-for='i in optionChain'>
        <v-container>
          <v-row>
            <v-col cols='4'>{{ i.strikeTime }}</v-col>
            <v-col>
              <v-row v-for='option in i.option'>
                <v-col>
                  <v-row v-for='(v, k) in option'>
                    <v-col>{{ k }}</v-col>
                    <v-col>{{ v.basic.security.code }}</v-col>
                    <v-col>{{ v.optionExData.strikePrice }}</v-col>
                  </v-row>
                </v-col>
              </v-row>
            </v-col>
          </v-row>
        </v-container>
      </v-col>
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
import moment from 'moment'
import {default as ws} from '../plugins/ws'
import {default as futu} from '../../../backend/futu'
require('model').default

export default
  props:
    initCode:
      type: String
      default:
        '00700'
  data: ->
    api: require('../plugins/api').default
    code: null
    name: null
    min: null
    max: null
    optionChain: []
    market: futu.QotMarket.QotMarket_HK_Security
    marketList: require('../plugins/const').default.marketList
  methods:
    setCode: (event) ->
      @name = await @api.getName {@market, @code}
  beforeMount: ->
    @code = @initCode
    @setCode()
  computed:
    strikeRange: ->
      [@min, @max]
  watch:
    strikeRange: ->
      if @min? and @max? and @max >= @min
        @optionChain = await @api.getOptionChain {@market, @code, @min, @max}
</script>

<style lang='scss' scoped>
.chart {
  height: 40vh;
}
</style>
