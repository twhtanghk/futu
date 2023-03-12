moment = require 'moment'
async = require 'async'
Router = require 'koa-router'
router = new Router()

module.exports = router
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
    {beginTime, endTime, page} = ctx.request.body
    page ?= 20
    endTime ?= moment()
      .format 'YYYY-MM-DD HH:mm:ss'
    elapsed = 1
    res = []
    ret = async.detectSeries res, ->
      if res.length >= page
        res.slice 0, page
      else
        beginTime ?= moment()
          .subtract day: elapsed++
          .format 'YYYY-MM-DD HH:mm:ss'
        console.log "#{beginTime} #{endTime}"
        res = await ctx.api.historyOrder {beginTime, endTime}
    console.log res
    console.log ret
    ctx.response.body = res
    await next()
