Futu = require('../index').default
Binance = require('binance').default
Koa = require 'koa'
logger = require 'koa-logger'
bodyParser = require 'koa-bodyparser'
methodOverride = require 'koa-methodoverride'
cors = require '@koa/cors'
router = require './router'
serve = require 'koa-static'
ws = require 'koa-websocket'

app = ws new Koa()
app.keys = process.env.KEYS?.split(',') || ['keep it secret']
do ->
  app.context.api =
    hk: await new Futu()
    crypto: await new Binance()
app
  .use logger()
  .use bodyParser()
  .use methodOverride()
  .use cors()
  .use router.routes()
  .use router.allowedMethods()
  .use serve 'dist'
  .on 'error', console.error
  .listen parseInt(process.env.PORT) || 3000
app.ws.server.on 'connection', (socket, req) ->
  socket.broker =
    hk: await new Futu()
    crypto: await new Binance()
app.ws.use (ctx) ->
  ctx.websocket
    .on 'message', (msg) ->
      require('./ws') ctx, JSON.parse msg.toString()
    .on 'error', (err) ->
      throw err
