_  = require 'lodash'
import {Promise} from 'bluebird'
import {EventEmitter} from 'events'
import moment from 'moment'
import ftWebsocket from 'futu-api'
import { ftCmdID } from 'futu-api'
import {Common, Qot_Common, Trd_Common} from 'futu-api/proto'
{TradeDateMarket, SubType, RehabType, KLType, QotMarket} = Qot_Common
{RetType} = Common
{ModifyOrderOp, OrderType, SecurityFirm, TrdMarket, TrdSecMarket, TrdEnv} = require('./backend/futu').default

global.WebSocket = require 'ws'

class Futu extends EventEmitter
  @marketMap:
    'hk': QotMarket.QotMarket_HK_Security

  @freqMap:
    '1': KLType.KLType_1Min
    '5': KLType.KLType_5Min
    '15': KLType.KLType_15Min
    '30': KLType.KLType_30Min
    '1h': KLType.KLType_60Min
    '1d': KLType.KLType_Day
    '1w': KLType.KLType_Week
    '1m': KLType.KLType_Month
    '3m': KLType.KLType_Quarter
    '1y': KLType.KLType_Year

  subList: []
  tradeSerialNo: 0
  trdEnv: if process.env.TRDENV? then parseInt process.env.TRDENV else TrdEnv.TrdEnv_Simulate

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
              {lastClosePrice} = await @basicQuote {code}
              @emit 'candle',
                market: market
                code: code
                timestamp: q.timestamp
                high: q.highPrice
                low: q.lowPrice
                open: q.openPrice
                close: q.closePrice
                lastClose: lastClosePrice
                volume: q.volume.low
                turnover: q.turnover
            when ftCmdID.TrdUpdateOrder.cmd
              {order} = s2c
              @emit 'trdUpdate', order
            when ftCmdID.TrdUpdateOrderFill.cmd
              {order} = s2c
              @emit 'trdUpdate', order
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

  plateSecurity: ({market, code} = {}) ->
    market ?= QotMarket.QotMarket_HK_Security
    code ?= 'HSI Constituent'
    (@errHandler await @ws.GetPlateSecurity
      c2s:
        plate: {market, code}).staticInfoList.map ({basic}) ->
          basic.security.code

  subInfo: ({isReqAllConn}={}) ->
    await @ws.GetSubInfo c2s: _.defaults {isReqAllConn}, isReqAllConn: true

  subscribeAcc: ({accIDList} = {}) ->
    accIDList ?= (await @accountList())
      .map ({accID}) ->
        accID
    @errHandler await @ws.SubAccPush c2s: {accIDList}

  subscribe: ({market, code, subtype}) ->
    market ?= QotMarket.QotMarket_HK_Security
    subtype ?= SubType.SubType_KL_1Min
    @subList.push {market, code, subtype}
    @errHandler await @ws.Sub
      c2s:
        securityList: [ {market, code} ]
        subTypeList: [subtype, SubType.SubType_Basic]
        isSubOrUnSub: true
        isRegOrUnRegPush: true

  unsubscribe: ({market, code, subtype}) ->
    subtype ?= SubType.SubType_KL_1Min
    @subList = @subList.filter (i) ->
      not (i.market == market and i.code == code and i.subtype == subtype)
    try
      @errHandler await @ws.Sub
        c2s:
          securityList: [ {market, code} ]
          subTypeList: [subtype]
          isSubOrUnSub: false
          isUnsubAll: false
    catch e
      throw e

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

  account: ({market, trdEnv} = {}) ->
    market ?= TrdMarket.TrdMarket_HK
    trdEnv ?= @trdEnv
    [first, ...] = (await @accountList())
      .filter (i) ->
        i.trdEnv == trdEnv and i.trdMarketAuthList.some (auth) ->
          auth == market
    first
    
  accountFund: ({market, trdEnv} = {}) ->
    market ?= TrdMarket.TrdMarket_HK
    trdEnv ?= @trdEnv
    {trdEnv, accID, trdMarketAuthList} = (await @account {market, trdEnv})
    req =
      c2s:
        header:
          trdEnv: trdEnv
          accID: accID
          trdMarket: trdMarketAuthList[0]
    @errHandler await @ws.GetFunds req

  position: ->
    {trdEnv, accID, trdMarketAuthList} = await @account()
    req =
      c2s:
        header:
          trdEnv: trdEnv
          accID: accID
          trdMarket: trdMarketAuthList[0]
    (@errHandler await @ws.GetPositionList req).positionList
    
  basicQuote: ({market, code}) ->
    market ?= QotMarket.QotMarket_HK_Security
    await @subscribe {market, code}
    req =
      c2s:
        securityList: [{market, code}]
    [ret, ...] = (@errHandler await @ws.GetBasicQot req).basicQotList
    ret
      
  orderList: ({market, trdEnv} = {}) ->
    market ?= TrdMarket.TrdMarket_HK
    trdEnv ?= @trdEnv
    {accID, trdMarketAuthList} = await @account()
    req =
      c2s:
        header:
          trdEnv: trdEnv
          accID: accID
          trdMarket: trdMarketAuthList[0]
    (@errHandler await @ws.GetOrderList req).orderList
    
  historyOrder: ({beginTime, endTime} = {}) ->
    loop
      endTime = if endTime? then beginTime else moment()
      beginTime = moment endTime
        .subtract year: 1
      {trdEnv, accID, trdMarketAuthList} = (await @account())
      req =
        c2s:
          header:
            trdEnv: trdEnv
            accID: accID
            trdMarket: trdMarketAuthList[0]
          filterConditions:
            beginTime: beginTime.format 'YYYY-MM-DD HH:mm:ss'
            endTime: endTime.format 'YYYY-MM-DD HH:mm:ss'
      ret = (@errHandler await @ws.GetHistoryOrderList req).orderList
      if ret.length == 0
        return
      else
        yield from ret

  historyDeal: ->
    loop
      endTime = if endTime? then beginTime else moment()
      beginTime = moment endTime
        .subtract year: 1
      {trdEnv, accID, trdMarketAuthList} = (await @account())
      req =
        c2s:
          header:
            trdEnv: trdEnv
            accID: accID
            trdMarket: trdMarketAuthList[0]
          filterConditions:
            beginTime: beginTime.format 'YYYY-MM-DD HH:mm:ss'
            endTime: endTime.format 'YYYY-MM-DD HH:mm:ss'
      ret = (@errHandler await @ws.GetHistoryOrderFillList req).orderFillList
      if ret.length == 0
        return
      else
        yield from ret
    
  placeOrder: ({trdEnv, trdMarket, trdSide, orderType, code, qty, price, secMarket}) ->
    trdEnv ?= @trdEnv
    trdMarket ?= TrdMarket.TrdMarket_HK
    orderType ?= OrderType.OrderType_Normal
    secMarket ?= TrdSecMarket.TrdSecMarket_HK
    req =
      c2s:
        packetID:
          connID: @ws.getConnID()
          serialNo: @tradeSerialNo++
        header:
          trdEnv: trdEnv
          accID: (await @account {trdEnv}).accID
          trdMarket: trdMarket
        trdSide: trdSide
        orderType: orderType
        code: code
        qty: qty
        price: price
        secMarket: secMarket
    (@errHandler await @ws.PlaceOrder req).orderID

  cancelOrder: ({id}) ->
    {accID, trdEnv, trdMarketAuthList} = await @account()
    [trdMarket, ...] = trdMarketAuthList 
    {qty, fillQty, price} = (await @orderList()).find ({orderID}) ->
      orderID.toString() == id
    req =
      c2s:
        packetID:
          connID: @ws.getConnID()
          serialNo: @tradeSerialNo++
        header:
          {trdEnv, accID, trdMarket}
        orderID: id
        modifyOrderOp: ModifyOrderOp.ModifyOrderOp_Cancel
        qty: qty - fillQty
        price: price
     @errHandler await @ws.ModifyOrder req   

  unlock: ({pwdMD5}) ->
    req =
      c2s:
        unlock: true
        securityFirm: SecurityFirm.SecurityFirm_FutuSecurities
        pwdMD5: pwdMD5
    @errHandler await @ws.UnlockTrade req

# input time ascending order of ohlc data
# i.e. [
#   {date, open, high, low, close}
#   ...
# ]
isSupport = (df, i) ->
  df[i].low < df[i - 1].low and 
  df[i].low < df[i + 1].low and
  df[i + 1].low < df[i + 2].low and
  df[i - 1].low < df[i - 2].low

# input time ascending order of ohlc data
# i.e. [
#   {date, open, high, low, close}
#   ...
# ]
isResistance = (df, i) ->
  df[i].high > df[i - 1].high and 
  df[i].high > df[i + 1].high and
  df[i + 1].high > df[i + 2].high and
  df[i - 1].high > df[i - 2].high

# mean of price range i.e. high - low
mean = (df) ->
  sum = 0
  for {high, low} in df
    sum += high - low
  sum / df.length

# check if price is too close to existng levels
meanDiff = (mean, price, levels) ->
  for [y, idx] in levels
    if Math.abs(price - y) < mean
      return false
  return true

# https://colab.research.google.com/drive/16yWD7FJ-moOc9jjymDgQjLXvW-yPKSf3?usp=sharing#scrollTo=kbcJ8L5nN1B-
# get list of support and resistance price levels
levels = (df) ->
  ret = []
  avg = mean df
  for i in [2..(df.length - 2)]
    if isSupport df, i
      if meanDiff avg, df[i].low, ret
        ret.push [df[i].low, i]
    if isResistance df, i
      if meanDiff avg, df[i].high, ret
        ret.push [df[i].high, i]
  ret

module.exports = {
  Futu
  isSupport
  isResistance
  mean
  meanDiff
  levels
}
