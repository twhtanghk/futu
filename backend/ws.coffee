_ = require 'lodash'
moment = require 'moment'
Futu = require('../index').default
{data, freqDuration} = require('algotrader/data').default
{filterByStdev} = require('algotrader/strategy').default

pageApi = {}

module.exports = (ctx, msg) ->
  console.log "<-- ws #{JSON.stringify msg}"
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
        {url, market, code, interval, beginTime} = msg
        pageApi[url] ?= {}
        pageApi[url].broker ?= await new Futu host: 'localhost', port: 33333
        opt =
          broker: pageApi[url].broker
          market: market
          code: code
          beginTime: moment().subtract freqDuration[interval]
          freq: interval
        pageApi[url].destroy?()
        {g, destroy} = await data opt
        pageApi[url].destroy = destroy
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
  ctx.api
    .on 'candle', (data) ->
      ctx.websocket.send JSON.stringify topic: 'candle', data: data
    .on 'orderBook', (data) ->
      ctx.websocket.send JSON.stringify topic: 'orderBook', data: data
    .on 'trdUpdate', (data) ->
      ctx.websocket.send JSON.stringify topic: 'trdUpdate', data: data
