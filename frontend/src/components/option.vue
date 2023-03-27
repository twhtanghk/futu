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
            <v-col cols='2'>{{ i.strikeTime }}</v-col>
            <v-col>
              <v-expansion-panels>
                <v-expansion-panel :title="'call ' + option.call.optionExData.strikePrice" @click='click($event, option.call)' v-for='option in i.option'>
                  <v-expansion-panel-text>
                    <order :code='option.call.basic.security.code'/>
                  </v-expansion-panel-text>
                </v-expansion-panel>
              </v-expansion-panels>
            </v-col>
            <v-col>
              <v-expansion-panels>
                <v-expansion-panel :title="'put ' + option.put.optionExData.strikePrice" @click='click($event, option.put)' v-for='option in i.option'>
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
      type: String
      default:
        '00700'
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
  methods:
    setCode: (event) ->
      @name = await api.getName {@market, @code}
  beforeMount: ->
    @code = @initCode
    @setCode()
  computed:
    strikeRange: ->
      [@min, @max]
  watch:
    strikeRange: ->
      if @min? and @max? and @max >= @min
        @optionChain = await api.getOptionChain {@market, @code, @min, @max}
</script>

<style lang='scss' scoped>
.chart {
  height: 40vh;
}
</style>
