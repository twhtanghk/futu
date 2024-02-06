_ = require 'lodash'
moment = require 'moment'
Futu = require('rxfutu').default
{freqDuration} = require('algotrader/data').default
{filterByStdev} = require('algotrader/rxStrategy').default

module.exports = (ctx, msg) ->
  msg = JSON.parse msg
  console.log "<-- ws #{JSON.stringify msg}"
  {action, url} = msg
  try
    switch action
      when 'subMarket'
        {market} = msg
        (await (await ctx.websocket.broker[market].accounts())[0].orders())
          .subscribe (i) ->
            ctx.websocket.send JSON.stringify topic: 'orderList', data: i.toJSON()
      when 'orderBook'
        {market, code} = msg
        (await ctx.websocket.broker[market].orderBook
          market: market
          code: code)
          .subscribe (i) ->
            ctx.websocket.send JSON.stringify topic: 'orderBook', data: i
      when 'unsubKL'
        {market, code, freq} = msg
        await ctx.websocket.broker[market].unsubKL
          market: market
          code: code
          freq: freq
      when 'unsubOrderBook'
        {market, code} = msg
        await ctx.websocket.broker[market].unsubOrderBook
          market: market
          code: code
      when 'ohlc'
        {market, code, freq, beginTime} = msg
        opt =
          market: market
          code: code
          start: moment().subtract freqDuration[freq].dataFetched
          freq: freq
        df = await ctx.websocket.broker[market].dataKL opt
        df.subscribe (i) ->
          ctx.websocket.send JSON.stringify topic: 'ohlc', data: i
      when 'constituent'
        {action, idx, beginTime, chunkSize, n} = msg
        opts =
          broker: ctx.api['hk']
          idx: idx
          beginTime: beginTime
          chunkSize: chunkSize
          n: n
        (await filterByStdev opts).map (df) ->
          df.subscribe (data) ->
            ctx.websocket.send JSON.stringify topic: 'constituent', data: data
  catch err
    console.error err
