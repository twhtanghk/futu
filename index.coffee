_  = require 'lodash'
import {Promise} from 'bluebird'
import {EventEmitter} from 'events'
import moment from 'moment'
import ftWebsocket from 'futu-api'
import { ftCmdID } from 'futu-api'
import {Common, Qot_Common} from 'futu-api/proto'
{TradeDateMarket, SubType, RehabType, KLType, QotMarket} = Qot_Common
{RetType} = Common

global.WebSocket = require 'ws'

class Futu extends EventEmitter
  subList: []

  constructor: ({host, port}) ->
    super()
    return do =>
      await new Promise (resolve, reject) =>
        @ws = new ftWebsocket()
        @ws.start host, port, false, null
        @ws.onlogin = resolve
        @ws.onPush = (cmd, {s2c}) =>
          switch cmd
            when ftCmdID.QotUpdateOrderBook.cmd
              {security, orderBookAskList, orderBookBidList} = s2c
              {market, code} = security
              @emit 'orderBook', 
                {market, code, orderBookAskList, orderBookBidList}
            when ftCmdID.QotUpdateKL.cmd
              {security, klList} = s2c
              {market, code} = security
              [q, ...] = klList
              @emit 'candle',
                market: market
                code: code
                timestamp: q.timestamp
                high: q.highPrice
                low: q.lowPrice
                open: q.openPrice
                close: q.closePrice
                volume: q.volume.low
                turnover: q.turnover
      @
      
  errHandler: ({errCode, retMsg, retType, s2c}) ->
    if retType != RetType.RetType_Succeed
      throw new Error "#{errCode}: #{retMsg}"
    else
      s2c

  # basic data
  marketState: (securityList) ->
    (@errHandler await @ws.GetMarketState c2s: {securityList})
      .marketInfoList

  capitalFlow: ({security}) ->
    await @ws.GetCapitalFlow c2s: {security}

  capitalDistribution: ({security}) ->
    await @ws.GetCapitalDistribution c2s: {security}

  ownerPlate: ({securityList}) ->
    await @ws.GetOwnerPlate c2s: {securityList}

  tradeDate: ({market, beginTime, endTime} = {}) ->
    market ?= TradeDateMarket.TradeDateMarket_HK
    beginTime = moment()
      .subtract month: 1
      .startOf 'month'
      .format 'YYYY-MM-DD'
    endTime ?= moment()
      .format 'YYYY-MM-DD'
    (@errHandler await @ws.RequestTradeDate c2s: {market, beginTime, endTime})
      .tradeDateList

  lastTradeDate: ->
    [..., last] = await @tradeDate()
    last
    
  historyKL: ({rehabType, klType, security, beginTime, endTime}) ->
    rehabType ?= RehabType.RehabType_Forward
    klType ?= KLType.KLType_1Min
    endTime ?= moment()
      .add days: 1
      .format 'YYYY-MM-DD' 
    switch klType
      when KLType.KLType_1Min, KLType.KLType_5Min, KLType.KLType_15Min
        beginTime ?= moment
          .unix (await @lastTradeDate()).timestamp
          .subtract day: 1
          .format 'YYYY-MM-DD'
      when KLType.KLType_30Min, KLType.KLType_60Min, KLType.KLType_Day
        beginTime ?= moment()
          .subtract month: 1
          .format 'YYYY-MM-DD' 
      when KLType.KLType_Week, KLType.KLType_Month
        beginTime ?= moment()
          .subtract month: 24
          .format 'YYYY-MM-DD' 
      when KLType.KLType_Year
        beginTime ?= moment()
          .subtract year: 30
          .format 'YYYY-MM-DD' 
    {security, klList} = @errHandler await @ws.RequestHistoryKL c2s: {rehabType, klType, security, beginTime, endTime}
    security: security
    klList: klList.map (i) ->
      {timestamp, openPrice, highPrice, lowPrice, closePrice, lastClosePrice, volume, turnover, changeRate} = i
      time: timestamp
      open: openPrice
      high: highPrice
      low: lowPrice
      close: closePrice
      lastClose: lastClosePrice
      volume: volume.low
      turnover: turnover
      changeRate: changeRate

  plateSet: ({market, placeSetType}={}) ->
    opts = _.defaults {market, placeSetType}, placeSetType: 0
    await @ws.GetPlateSet c2s: opts

  plateSecurity: ({market, code}) ->
    (@errHandler await @ws.GetPlateSecurity
      c2s:
        plate: {market, code}).staticInfoList

  subInfo: ({isReqAllConn}={}) ->
    await @ws.GetSubInfo c2s: _.defaults {isReqAllConn}, isReqAllConn: true

  subscribe: ({market, code, subtype}) ->
    subtype ?= SubType.SubType_KL_1Min
    @subList.push {market, code, subtype}
    @errHandler await @ws.Sub
      c2s:
        securityList: [ {market, code} ]
        subTypeList: [subtype]
        isSubOrUnSub: true
        isRegOrUnRegPush: true

  unsubscribe: ({market, code, subtype}) ->
    subtype ?= SubType.SubType_KL_1Min
    @subList = @subList.filter (i) ->
      not (i.market == market and i.code == code and i.subtype == subtype)
    @errHandler await @ws.Sub
      c2s:
        securityList: [ {market, code} ]
        subTypeList: [subtype]
        isSubOrUnSub: false
        isUnsubAll: false

  optionChain: ({code, strikeRange, beginTime, endTime}) ->
    beginTime ?= moment()
      .startOf 'month'
      .format 'YYYY-MM-DD'
    endTime ?= moment()
      .endOf 'month'
      .format 'YYYY-MM-DD'
    {optionChain} = @errHandler await @ws.GetOptionChain
      c2s:
        owner:
          market: QotMarket.QotMarket_HK_Security
          code: code
        beginTime: beginTime
        endTime: endTime
    _.map optionChain, ({option, strikeTime, strikeTimestamp}) ->
      strikeTime: strikeTime
      option: _.filter option, ({call, put}) ->
        {basic, optionExData} = call
        {strikePrice} = optionExData
        [min, max] = strikeRange
        min <= strikePrice and strikePrice <= max
      
  accountList: ->
    (@errHandler await @ws.GetAccList c2s: userID: 0).accList

  accountFund: ->
    [{trdEnv, accID, trdMarketAuthList}, ...] = (await @accountList())
      .filter ({trdEnv, trdMarketAuthList}) ->
        trdEnv == 1 and trdMarketAuthList.some (auth) ->
          auth == 1
    req =
      c2s:
        header:
          trdEnv: trdEnv
          accID: accID.low
          traMarket: trdMarketAuthList[0]
    @errHandler await @ws.GetFunds req

module.exports =
  Futu: Futu
