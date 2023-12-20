_ = require 'lodash'
moment = require 'moment'
Futu = require('../index').default
{data} = require('algotrader/data').default
{filterByStdev} = require('algotrader/strategy').default

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
      when 'constituent'
        {action, idx, beginTime, chunkSize, n} = msg
        opts =
          broker: ctx.api
          idx: idx
          beginTime: beginTime
          chunkSize: chunkSize
          n: n
        data = await filterByStdev opts
        ctx.websocket.send JSON.stringify topic: 'constituent', data: data
  catch err
    console.error err
  ctx.api
    .on 'candle', (data) ->
      ctx.websocket.send JSON.stringify topic: 'candle', data: data
    .on 'orderBook', (data) ->
      ctx.websocket.send JSON.stringify topic: 'orderBook', data: data
    .on 'trdUpdate', (data) ->
      ctx.websocket.send JSON.stringify topic: 'trdUpdate', data: data
