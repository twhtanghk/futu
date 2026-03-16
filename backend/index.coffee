import {Futu} from 'algotrader/futu.js'
import Binance from 'binance'
import Koa from 'koa'
import logger from 'koa-logger'
import bodyParser from 'koa-bodyparser'
import methodOverride from 'koa-methodoverride'
import cors from '@koa/cors'
import router from './router'
import serve from 'koa-static'
import ws from 'koa-websocket'

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
