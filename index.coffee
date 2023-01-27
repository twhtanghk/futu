_  = require 'lodash'
import {EventEmitter} from 'events'
import moment from 'moment'
import ftWebsocket from 'futu-api'
import {Common, Qot_Common} from 'futu-api/proto'
{SubType, RehabType, KLType, QotMarket} = Qot_Common
{RetType} = Common

_ = require 'lodash'
Promise = require 'bluebird'
global.WebSocket = require 'ws'

class Futu extends EventEmitter
  symbols: []

  constructor: ({host, port}) ->
    super()
    return do =>
      await new Promise (resolve, reject) =>
        @ws = new ftWebsocket()
        @ws.start host, port, false, null
        @ws.onlogin = resolve
        @ws.onPush = (cmd, {s2c}) =>
          {security, klList} = s2c
          {code} = security
          [q, ...] = klList
          @emit '1',
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
  marketState: ({securityList}={}) ->
    await @ws.GetMarketState c2s: {securityList}

  capitalFlow: ({security}) ->
    await @ws.GetCapitalFlow c2s: {security}

  capitalDistribution: ({security}) ->
    await @ws.GetCapitalDistribution c2s: {security}

  ownerPlate: ({securityList}) ->
    await @ws.GetOwnerPlate c2s: {securityList}

  historyKL: ({rehabType, klType, security, beginTime, endTime}) ->
    rehabType ?= RehabType.RehabType_Forward
    klType ?= KLType.KLType_1Min
    beginTime ?= moment()
      .format 'yyyy-MM-DD'
    endTime ?= moment()
      .add days: 1
      .format 'yyyy-MM-DD' 
    await @ws.RequestHistoryKL c2s: {rehabType, klType, security, beginTime, endTime}

  plateSet: ({market, placeSetType}={}) ->
    opts = _.defaults {market, placeSetType}, placeSetType: 0
    await @ws.GetPlateSet c2s: opts

  subInfo: ({isReqAllConn}={}) ->
    await @ws.GetSubInfo c2s: _.defaults {isReqAllConn}, isReqAllConn: true

  securityList: ->
    @symbols
      .map (code) ->
        market: QotMarket.QotMarket_HK_Security
        code: code

  subscribe: (codes) ->
    if not Array.isArray codes
      codes = [codes]
    @symbols = _
      .union @symbols, codes
      .sort()
    await @ws.Sub
      c2s:
        securityList: @securityList()
        subTypeList: [SubType.SubType_KL_1Min]
        isSubOrUnSub: true
        isRegOrUnRegPush: true

  unsubscribe: (codes=@symbols) ->
    # unsubscribe all
    await @ws.Sub
      c2s:
        securityList: @securityList()
        subTypeList: [SubType.SubType_KL_1Min]
        isSubOrUnSub: false
        isUnsubAll: true

    # remove input codes from symbols
    if not Array.isArray codes
      codes = [codes]
      @symbols = _.difference @symbols, codes
      await @subscribe @symbols

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
      
module.exports =
  Futu: Futu
