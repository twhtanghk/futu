<template>
  <v-container>
    <v-row>
      <v-col md='2'>{{ name }}</v-col>
      <v-col md='3'><v-select density='compact' :items='marketList' item-title='text' item-value='value' v-model='market'/></v-col>
      <v-col md='3'><v-select density='compact' :items='dateList' v-model='expiryDate'/></v-col>
      <v-col md='2'><v-text-field density='compact' v-model='code' @keyup.enter='setCode'/></v-col>
      <v-col md='1'><v-text-field density='compact' v-model.number='min'/></v-col>
      <v-col md='1'><v-text-field density='compact' v-model.number='max'/></v-col>
    </v-row>
    <v-row no-gutters>
      <v-col v-for='i in optionChain'>
        <v-container>
          <v-row>
            <v-col cols='2'>{{ i.strikeTime }}</v-col>
            <v-col>
              <v-expansion-panels v-for='option in i.option'>
                <v-expansion-panel :title="'call ' + option.call.optionExData.strikePrice">
                  <v-expansion-panel-text>
                    <order :code='option.call.basic.security.code'/>
                  </v-expansion-panel-text>
                </v-expansion-panel>
              </v-expansion-panels>
            </v-col>
            <v-col>
              <v-expansion-panels v-for='option in i.option'>
                <v-expansion-panel :title="'put ' + option.put.optionExData.strikePrice">
                  <v-expansion-panel-text>
                    <order :code='option.put.basic.security.code'/>
                  </v-expansion-panel-text>
                </v-expansion-panel>
              </v-expansion-panels>
            </v-col>
          </v-row>
        </v-container>
      </v-col>
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
import moment from 'moment'
import {default as api} from '../plugins/api'
import {default as futu} from '../../../backend/futu'
import order from './order'

export default
  props:
    initCode:
      type: Array
  components:
    order: order
  data: ->
    code: null
    name: null
    min: null
    max: null
    optionChain: []
    market: futu.QotMarket.QotMarket_HK_Security
    marketList: require('../plugins/const').default.marketList
    expiryDate: @comingMonth()[0]
    dateList: @comingMonth()
  methods:
    setCode: (event) ->
      @name = await api.getName {@market, @code}
    comingMonth: ->
      curr = moment().startOf 'month'
      [
        curr
        moment(curr).add month: 1
        moment(curr).add month: 2
      ].map (i) ->
        i.format 'YYYY-MM'
  beforeMount: ->
    [@code, @expiryDate, @min, @max] = @initCode
    @expiryDate ?= @comingMonth()[0]
    @setCode()
  computed:
    strikeParam: ->
      [@expiryDate, @min, @max]
  watch:
    strikeParam: ->
      if @min? and @max? and @max >= @min
        @$emit 'update:initCode', [@code, @expiryDate, @min, @max]
        beginTime = moment @expiryDate, 'YYYY-MM'
          .startOf 'month'
          .format 'YYYY-MM-DD'
        endTime = moment beginTime
          .endOf 'month'
          .format 'YYYY-MM-DD'
        @optionChain = await api.getOptionChain {@market, @code, @min, @max, beginTime, endTime}
</script>

<style lang='scss' scoped>
.chart {
  height: 40vh;
}
</style>
