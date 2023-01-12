import {EventEmitter} from 'events'
import ftWebsocket from 'futu-api'
import {Qot_Common} from 'futu-api/proto'
{SubType, QotMarket} = Qot_Common

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
    await @ws.RequestHistoryKL c2s: {rehabType, klType, security, beginTime, endTime}

  plateSet: ({market, placeSetType}={}) ->
    opts = _.defaults {market, placeSetType}, placeSetType: 0
    await @ws.GetPlateSet c2s: opts

  subInfo: ({isReqAllConn}={}) ->
    await @ws.GetSubInfo c2s: _.defaults {isReqAllConn}, isReqAllConn: true

  subscribe: (codes) ->
    if not Array.isArray codes
      codes = [codes]
    @symbols = @symbols
      .concat codes
      .sort()
    securityList = @symbols
      .map (code) ->
        market: QotMarket.QotMarket_HK_Security
        code: code
    @ws.Sub
      c2s:
        securityList: securityList
        subTypeList: [SubType.SubType_KL_1Min]
        isSubOrUnSub: true
        isRegOrUnRegPush: true

module.exports =
  Futu: Futu
