moment = require 'moment'
Futu = require('rxfutu').default
Router = require 'koa-router'
router = new Router()
{freqDuration} = require('algotrader/data').default
{ohlc} = require('algotrader/analysis').default
import {buffer, last} from 'rxjs'

module.exports = router
  # get support or resistance levels of specifed stock
  # req.body = {market, code, freq, beginTime, endTime}
  # res.body = {level: [price1, price2, ...]
  .get '/api/level', (ctx, next) ->
    {market, code, freq, beginTime, endTime} = ctx.request.body
    market ?= 'hk'
    endTime = moment()
    beginTime = moment endTime
      .subtract 6, 'month'
    freq ?= '1d'
    df = await ctx.api[market].historyKL
      market: market
      code: code
      start: beginTime
      end: endTime
      freq: freq
    df
      .pipe buffer df
      .pipe last()
      .subscribe (list) ->
        ctx.response.body = ohlc
          .levels list
            .map ([price, idx]) ->
              price
          .sort (a, b) ->
            a - b
        await next()
  .get '/api/candle', (ctx, next) ->
    {rehabType, klType, security, beginTime, endTime} = ctx.request.body
    security.market = Futu.marketMap[security.market]
    ctx.response.body = await ctx.api[security.market].historyKL 
      market: security.market
      code: security.code
      freq: klType
    await next()
  .get '/api/name', (ctx, next) ->
    {market, code} = ctx.request.body
    ctx.response.body = await ctx.api[market].marketState {market, code}
    await next()
  .get '/api/quote', (ctx, next) ->
    {market, code} = ctx.request.body
    res = await ctx.api[market].basicQuote {market, code}
    ctx.response.body =
      high: res.highPrice
      low: res.lowPrice
      open: res.openPrice
      close: res.curPrice
      last: res.lastClosePrice
    await next()
  .get '/api/optionChain', (ctx, next) ->
    {market, code, min, max, beginTime, endTime} = ctx.request.body
    if beginTime?
      beginTime = moment beginTime
    if endTime?
      endTime = moment endTime
    strikeRange = [min, max]
    opts = {market, code, strikeRange, beginTime, endTime}
    ctx.response.body = await ctx.api[market].optionChain opts
    await next()
  .get '/api/position', (ctx, next) ->
    market = 'hk'
    ctx.response.body = await (await ctx.api[market].accounts())[0].position()
    await next()
  .get '/api/order', (ctx, next) ->
    market = 'hk'
    ctx.response.body = await ctx.api[market].orderList()
    await next()
  .get '/api/deal', (ctx, next) ->
    market = 'hk'
    ctx.response.body = await ctx.api[market].historyDeal()
    await next()
  .post '/api/trade', (ctx, next) ->
    {market, code, side, qty, price} = ctx.request.body
    ctx.response.body = (await ctx.api[market].defaultAcc())
      .placeOrder {code, side, qty, price}
    await next()
  .del '/api/trade/:id', (ctx, next) ->
    market = 'hk'
    ctx.response.body = await (await ctx.api[market].accounts())[0].cancelOrder id: parseInt ctx.request.params.id
    await next()
  .put '/api/trade/unlock', (ctx, next) ->
    {market, pwdMD5} = ctx.request.body
    market ?= 'hk'
    await ctx.api[market].unlock {pwdMD5}
    ctx.response.body = {}
    await next()
  # via algotrader interface
  .get '/api/history', (ctx, next) ->
    {market, code, start, end, freq} = ctx.request.body
    market ?= 'hk'
    end = if end? then moment(end) else moment()
    start = if start? then moment(start) else moment(end).subtract freqDuration[freq].dataFetched
    (await ctx.api[market].historyKL
      market: market
      code: code
      start: start
      end: end
      freq: freq)
      .pipe buffer()
      .pipe last()
      .subscribe (x) ->
        ctx.response.body = x
        await next()
