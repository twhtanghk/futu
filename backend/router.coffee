{Futu} = require '../index'
Router = require 'koa-router'
router = new Router()
api = null
do ->
  api = await new Futu host: 'localhost', port: 33333

module.exports = router
  .get '/api/candle', (ctx, next) ->
    {rehabType, klType, security, beginTime, endTime} = ctx.request.body
    ctx.response.body = await api.historyKL {rehabType, klType, security, beginTime, endTime}
    await next()
  .get '/api/name', (ctx, next) ->
    {market, code} = ctx.request.body
    if not Array.isArray code
      code = [code]
    ctx.response.body = await api.marketState code.map (i) ->
      market: market
      code: i
    await next()
