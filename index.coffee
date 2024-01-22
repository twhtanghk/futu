_  = require 'lodash'
import {Readable} from 'stream'
import {Promise} from 'bluebird'
import {EventEmitter} from 'events'
import moment from 'moment'
import ftWebsocket from 'futu-api'
import { ftCmdID } from 'futu-api'
import {Common, Qot_Common, Trd_Common} from 'futu-api/proto'
{TradeDateMarket, SubType, RehabType, KLType, QotMarket} = Qot_Common
{RetType} = Common
{ModifyOrderOp, OrderType, OrderStatus, SecurityFirm, TrdEnv, TrdMarket, TrdSecMarket, TrdSide} = Trd_Common
{Broker, freqDuration} = AlgoTrader = require('algotrader/data').default

class Account extends AlgoTrader.Account
  constructor: (opts) ->
    super()
    {broker, trdEnv, accID, trdMarketAuthList, accType, cardNum, securityFirm} = opts
    @broker = broker
    @id = accID
    @trdEnv = trdEnv
    @market = trdMarketAuthList
    @type = accType
    @cardNum = cardNum
    @securityFirm = securityFirm

  position: ->
    req =
      c2s:
        header:
          trdEnv: @trdEnv
          accID: @id
          trdMarket: @market[0]
    (@broker.errHandler await @broker.ws.GetPositionList req).positionList

class Futu extends Broker
  @marketMap:
    'hk': QotMarket.QotMarket_HK_Security
    'us': QotMarket.QotMarket_US_Security

  @subTypeMap:
    'Basic': SubType.SubType_Basic
    'Broker': SubType.SubType_Broker
    '1': SubType.SubType_KL_1Min
    '5': SubType.SubType_KL_5Min
    '15': SubType.SubType_KL_15Min
    '30': SubType.SubType_KL_30Min
    '1h': SubType.SubType_KL_60Min
    '1d': SubType.SubType_KL_Day
    '1w': SubType.SubType_KL_Week
    '1m': SubType.SubType_KL_Month
    '3m': SubType.SubType_KL_Quarter
    '1y': SubType.SubType_KL_Year

  @freqMap: Futu.subTypeMap

  @klTypeMap:
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

  @constant: {
    Common
    KLType
    ModifyOrderOp
    OrderStatus
    OrderType
    Qot_Common
    QotMarket
    RehabType
    RetType
    SecurityFirm
    SubType
    TradeDateMarket
    Trd_Common
    TrdEnv
    TrdMarket
    TrdSide
    TrdSecMarket
  }

  subList: []
  tradeSerialNo: 0
  trdEnv: if process.env.TRDENV? then parseInt process.env.TRDENV else TrdEnv.TrdEnv_Simulate

  constructor: ({host, port} = {}) ->
    super()
    host ?= 'localhost'
    port ?= 33333
    global.WebSocket = require 'ws'
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
              {klType, security, klList} = s2c
              {market, code} = security
              [q, ...] = klList
              @emit 'candle',
                market: _.invert(Futu.marketMap)[market]
                code: code
                freq: _.invert(Futu.klTypeMap)[klType]
                timestamp: q.timestamp
                high: q.highPrice
                low: q.lowPrice
                open: q.openPrice
                close: q.closePrice
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
    
  historyKL: ({market, code, start, end, freq}) ->
    security =
      market: Futu.marketMap[market]
      code: code
    rehabType = RehabType.RehabType_Forward
    klType = Futu.klTypeMap[freq]
    beginTime = (start || moment().subtract freqDuration[freq])
      .format 'YYYY-MM-DD'
    endTime = (end || moment())
      .format 'YYYY-MM-DD HH:mm:ss' 
    {klList} = @errHandler await @ws.RequestHistoryKL c2s: {rehabType, klType, security, beginTime, endTime}
    klList.map (i) ->
      {timestamp, openPrice, highPrice, lowPrice, closePrice, volume, turnover, changeRate} = i
      market: market
      code: code
      freq: freq
      timestamp: timestamp
      open: openPrice
      high: highPrice
      low: lowPrice
      close: closePrice
      volume: volume.low
      turnover: turnover
      changeRate: changeRate

  streamKL: ({market, code, freq}) ->
    ret = new Readable
      objectMode: true
      read: ->
        @pause()
      destroy: =>
        await @unsubscribe {market, code, freq}
    await @subscribe {market, code, subtype: Futu.subTypeMap[freq]}
    @on 'candle', (data) ->
      if market == data.market and code == data.code and freq == data.freq
        ret.resume()
        ret.push data
    ret

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
    market ?= 'hk'
    market = Futu.marketMap[market]
    @subList.push {market, code, subtype}
    @errHandler await @ws.Sub
      c2s:
        securityList: [ {market, code} ]
        subTypeList: [subtype]
        isSubOrUnSub: true
        isRegOrUnRegPush: true

  unsubscribe: ({market, code, freq}) ->
    market ?= 'hk'
    market = Futu.marketMap[market]
    freq ?= '1'
    subtype = Futu.subTypeMap[freq]
    @subList = @subList.filter (i) ->
      not (i.market == market and i.code == code and i.freq == freq)
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
    market ?= 'hk'
    await @subscribe {market, code, subtype: SubType.SubType_Basic}
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

  accounts: ->
    (@errHandler await @ws.GetAccList c2s: userID: 0)
      .accList
      .filter ({trdEnv, trdMarketAuthList}) ->
        # real account and hk in market list
        trdEnv == 1 and 1 in trdMarketAuthList
      .map (acc) =>
        acc.broker = @
        new Account acc

export default Futu
