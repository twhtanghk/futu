_ = require 'lodash'
moment = require 'moment'
Futu = require('../index').default
{data} = require 'algotrader/data'
subType = 
  '1': Futu.constant.SubType.SubType_KL_1Min
  '5': Futu.constant.SubType.SubType_KL_5Min
  '15': Futu.constant.SubType.SubType_KL_15Min

module.exports = (ctx, msg) ->
  {action} = msg
  try
    switch action
      when 'subscribeAcc'
        await ctx.api.subscribeAcc()
      when 'subscribe'
        {subtype, market, code, interval} = msg
        if interval of (k for k, v of Futu.klTypeMap)
          subtype = Futu.subTypeMap[interval]
        await ctx.api.subscribe 
          market: market
          code: code
          subtype: subtype
      when 'unsubscribe'
        {market, code, interval} = msg
        await ctx.api.unsubscribe 
          market: market
          code: code
          subtype: Futu.subTypeMap[interval]
      when 'ohlc'
        {market, code, interval, beginTime} = msg
        console.log msg
        opt =
          broker: ctx.api
          market: market
          code: code
          beginTime: do ->
            elapsed =
              '1': day: 1
              '5': day: 1
              '15': day: 1
              '30': day: 3
              '1h': day: 3
              '1d': year: 1
              '1w': year: 10
              '1m': year: 30
              '3m': year: 30
              '1y': year: 60
            moment().subtract elapsed[interval]
          freq: interval
        for await i from data opt
          i.code = code
          ctx.websocket.send JSON.stringify topic: 'ohlc', data: i
  catch err
    console.error err
  ctx.api
    .on 'candle', (data) ->
      ctx.websocket.send JSON.stringify topic: 'candle', data: data
    .on 'orderBook', (data) ->
      ctx.websocket.send JSON.stringify topic: 'orderBook', data: data
    .on 'trdUpdate', (data) ->
      ctx.websocket.send JSON.stringify topic: 'trdUpdate', data: data
