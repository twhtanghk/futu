import moment from 'moment'
import {firstValueFrom, takeLast, toArray} from 'rxjs'
import brokerLib from 'algotrader/broker.js'
import rxStrategy from 'algotrader/rxStrategy.js'

{freqDuration} = brokerLib
{meanClose, meanVol} = rxStrategy

export default (ctx, msg) ->
  # rxjs WebSocketSubject stringifies outgoing values by default, while the
  # frontend already sends a JSON string, so msg can arrive as a string
  msg = JSON.parse msg if typeof msg is 'string'
  console.log "<-- ws #{JSON.stringify msg}"
  {action, url} = msg
  try
    unless ctx.websocket.broker?
      ctx.websocket.broker = await ctx.websocket.brokerReady if ctx.websocket.brokerReady?
    broker = ctx.websocket.broker
    unless broker?
      return console.error 'broker not ready'
    switch action
      when 'subMarket'
        {market} = msg
        ctx.websocket.orderSubs ?= {}
        unless ctx.websocket.orderSubs[market]
          [account] = await broker[market].accounts()
          account = await account
          unless account?
            return console.error "no trading account for #{market}"
          ctx.websocket.orderSubs[market] = true
          seen = {}
          (await account.historyOrder()).subscribe (data) ->
            seen[data.id] = true
            ctx.websocket.send JSON.stringify {topic: 'orderList', data}
          (await account.streamOrder()).subscribe (data) ->
            topic = if seen[data.id] then 'orderChg' else 'orderAdd'
            seen[data.id] = true
            ctx.websocket.send JSON.stringify {topic, data}
      when 'orderBook'
        {market, code} = msg
        (await broker[market].orderBook
          market: market
          code: code)
          .subscribe (i) ->
            ctx.websocket.send JSON.stringify topic: 'orderBook', data: i
      when 'unsubKL'
        {market, code, freq} = msg
        await broker[market].unsubKL
          market: market
          code: code
          freq: freq
      when 'unsubOrderBook'
        {market, code} = msg
        await broker[market].unsubOrderBook
          market: market
          code: code
      when 'ohlc'
        {market, code, freq, beginTime} = msg
        opt =
          market: market
          code: code
          start: moment().subtract freqDuration[freq].dataFetched
          freq: freq
        df = await broker[market].dataKL opt
        df.subscribe (i) ->
          # dataKL turns timestamp into a moment object, which serializes to
          # an ISO string; the chart expects unix seconds
          i.timestamp = i.timestamp.unix()
          ctx.websocket.send JSON.stringify topic: 'ohlc', data: i
      when 'constituent'
        {idx, beginTime, chunkSize, n} = msg
        idx ?= 'HSI Constituent Stocks'
        beginTime = moment(beginTime) if beginTime?
        beginTime ?= moment().subtract 6, 'month'
        chunkSize ?= 60
        list = await broker['hk'].plateSecurity {code: idx}
        for {code, name} in list
          break unless ctx.websocket.readyState is 1
          await new Promise (resolve) -> setTimeout resolve, 1000
          df = await broker['hk'].historyKL
            market: 'hk'
            code: code
            start: beginTime
            freq: '1d'
          x = await firstValueFrom df.pipe takeLast(chunkSize), toArray()
          [end] = x.slice -1
          data = {market: 'hk', code: code, name: name, freq: '1d'}
          Object.assign data, end, meanClose(x), meanVol(x)
          ctx.websocket.send JSON.stringify topic: 'constituent', data: data
  catch err
    console.error err
