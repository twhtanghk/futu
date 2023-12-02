moment = require 'moment'
Router = require 'koa-router'
router = new Router()
{history} = require 'algotrader/data'
{ohlc} = require 'algotrader/analysis'

module.exports = router
  # get support or resistance levels of specifed stock
  # req.body = {market, code, freq, beginTime, endTime}
  # res.body = {level: [price1, price2, ...]
  .get '/api/level', (ctx, next) ->
    {market, code, freq, beginTime, endTime} = ctx.request.body
    endTime = moment()
    beginTime = moment endTime
      .subtract 6, 'month'
    df = await history 
      broker: ctx.api
      market: market
      code: code
      start: beginTime
      end: endTime
      freq: freq
    ctx.response.body = ohlc
      .levels df
      .map ([price, idx]) ->
        price
      .sort (a, b) ->
        a - b
    await next()
  .get '/api/candle', (ctx, next) ->
    {rehabType, klType, security, beginTime, endTime} = ctx.request.body
    ctx.response.body = await ctx.api.historyKL {rehabType, klType, security, beginTime, endTime}
    await next()
  .get '/api/name', (ctx, next) ->
    {market, code} = ctx.request.body
    if not Array.isArray code
      code = [code]
    ctx.response.body = await ctx.api.marketState code.map (i) ->
      market: market
      code: i
    await next()
  .get '/api/quote', (ctx, next) ->
    {market, code} = ctx.request.body
    res = await ctx.api.basicQuote {market, code}
    ctx.response.body =
      high: res.highPrice
      low: res.lowPrice
      open: res.openPrice
      close: res.curPrice
      last: res.lastClosePrice
    await next()
  .get '/api/optionChain', (ctx, next) ->
    {market, code, min, max, beginTime, endTime} = ctx.request.body
    strikeRange = [min, max]
    opts = {market, code, strikeRange, beginTime, endTime}
    ctx.response.body = await ctx.api.optionChain opts
    await next()
  .get '/api/position', (ctx, next) ->
    ctx.response.body = await ctx.api.position()
    await next()
  .get '/api/order', (ctx, next) ->
    ctx.response.body = await ctx.api.orderList()
    await next()
  .get '/api/deal', (ctx, next) ->
    ctx.response.body = await ctx.api.historyDeal()
    await next()
  .post '/api/trade', (ctx, next) ->
    {trdSide, code, qty, price} = ctx.request.body
    ctx.response.body = await ctx.api.placeOrder {trdSide, code, qty, price}
    await next()
  .get '/api/trade', (ctx, next) ->
    {endTime, page} = ctx.request.body
    page ?= 20
    endTime = if endTime? then moment(endTime, 'YYYY-MM-DD HH:mm:ss') else moment()
    elapsed = 5
    res = []
    test = (cb) ->
      if res.length >= page
        res.slice 0, page
      else
        await cb()
    nextPage = ->
      beginTime = moment endTime
        .subtract day: elapsed++
      res = await ctx.api.historyOrder
        beginTime: beginTime.format 'YYYY-MM-DD HH:mm:ss'
        endTime: endTime.format 'YYYY-MM-DD HH:mm:ss'
      await test nextPage
    ctx.response.body = await test nextPage
    await next()
  .del '/api/trade/:id', (ctx, next) ->
    ctx.response.body = await ctx.api.cancelOrder id: ctx.request.params.id
    await next()
  .put '/api/trade/unlock', (ctx, next) ->
    {pwdMD5} = ctx.request.body
    await ctx.api.unlock {pwdMD5}
    ctx.response.body = {}
    await next()
