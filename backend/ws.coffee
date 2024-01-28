_ = require 'lodash'
moment = require 'moment'
Futu = require('rxfutu').default
{freqDuration} = require('algotrader/data').default
{filterByStdev} = require('algotrader/strategy').default

module.exports = (ctx, msg) ->
  console.log "<-- ws #{JSON.stringify msg}"
  {action, url} = msg
  try
    switch action
      when 'subscribeAcc'
        await ctx.websocket.broker.subscribeAcc()
      when 'orderBook'
        {market, code} = msg
        (await ctx.websocket.broker[market].orderBook
          market: market
          code: code)
          .subscribe (i) ->
            ctx.websocket.send JSON.stringify topic: 'orderBook', data: i
      when 'unsubscribe'
        {market, code, interval} = msg
        await ctx.websocket.broker[market].unsubKL
          market: market
          code: code
          freq: interval
      when 'ohlc'
        {market, code, interval, beginTime} = msg
        opt =
          market: market
          code: code
          start: moment().subtract freqDuration[interval].dataFetched
          freq: interval
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
        data = await filterByStdev opts
        ctx.websocket.send JSON.stringify topic: 'constituent', data: data
  catch err
    console.error err
