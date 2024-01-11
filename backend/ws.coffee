_ = require 'lodash'
moment = require 'moment'
Futu = require('../index').default
{freqDuration} = require('algotrader/data').default
{filterByStdev} = require('algotrader/strategy').default

module.exports = (ctx, msg) ->
  console.log "<-- ws #{JSON.stringify msg}"
  {action, url} = msg
  try
    switch action
      when 'subscribeAcc'
        await ctx.websocket.broker.subscribeAcc()
      when 'subscribe'
        {subtype, market, code, interval} = msg
        if interval of (k for k, v of Futu.klTypeMap)
          subtype = Futu.subTypeMap[interval]
        await ctx.websocket.broker.subscribe 
          market: market
          code: code
          subtype: subtype
        ctx.websocket.broker
          .on 'candle', (data) ->
            ctx.websocket.send JSON.stringify topic: 'candle', data: data
          .on 'orderBook', (data) ->
            ctx.websocket.send JSON.stringify topic: 'orderBook', data: data
          .on 'trdUpdate', (data) ->
            ctx.websocket.send JSON.stringify topic: 'trdUpdate', data: data
      when 'unsubscribe'
        {market, code, interval} = msg
        await ctx.websocket.broker.unsubscribe 
          market: market
          code: code
          freq: interval
      when 'ohlc'
        {market, code, interval, beginTime} = msg
        opt =
          market: market
          code: code
          start: moment().subtract freqDuration[interval]
          freq: interval
        {g, destroy} = await ctx.websocket.broker.dataKL opt
        for await i from g()
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
