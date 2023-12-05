<template>
  <v-container>
    <v-row>
      <v-col>{{ name }}</v-col>
      <v-col><v-select density='compact' :items='dateList' v-model='expiryDate'/></v-col>
      <v-col><v-text-field density='compact' v-model='code' @keyup.enter='setCode'/></v-col>
      <v-col><v-text-field density='compact' v-model.number='min'/></v-col>
      <v-col><v-text-field density='compact' v-model.number='max'/></v-col>
    </v-row>
    <v-row no-gutters>
      <v-col v-for='i in optionChain'>
        <v-container>
          <v-row>
            <v-col>{{ i.strikeTime }}</v-col>
          </v-row>
          <v-row>
            <v-expansion-panels v-for='option in i.option'>
              <v-expansion-panel :title="option.call.optionExData.strikePrice">
                <v-expansion-panel-text>
                  <v-row>
                    <v-col>
                      <order :code='option.call.basic.security.code'/>
                    </v-col>
                    <v-col>
                      <order :code='option.put.basic.security.code'/>
                    </v-col>
                  </v-row>
                </v-expansion-panel-text>
              </v-expansion-panel>
            </v-expansion-panels>
          </v-row>
        </v-container>
      </v-col>
    </v-row>
  </v-container>
</template>

<script lang='coffee'>
import moment from 'moment'
import {default as api} from '../plugins/api'
import {default as Futu} from '../../../index'
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
    market: Futu.constant.QotMarket.QotMarket_HK_Security
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
    {close} = await api.getQuote {@market, @code}
    @min = close * 0.9
    @max = close * 1.1
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
