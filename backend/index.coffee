import {Futu} from 'algotrader/futu.js'
import Koa from 'koa'
import logger from 'koa-logger'
import bodyParser from 'koa-bodyparser'
import methodOverride from 'koa-methodoverride'
import cors from '@koa/cors'
import router from './router.js'
import wsHandler from './ws.js'
import serve from 'koa-static'
import ws from 'koa-websocket'

app = ws new Koa()
apiReady = do ->
  try
    hk: await new Futu()
  catch err
    console.error 'futu login failed', err
    null
app
  .use logger()
  .use bodyParser()
  .use methodOverride()
  .use cors()
  .use (ctx, next) ->
    # wait for the futu client before handling api calls
    ctx.api = await apiReady if ctx.path.startsWith '/api'
    await next()
  .use router.routes()
  .use router.allowedMethods()
  .use serve 'dist'
  .on 'error', console.error
  .listen parseInt(process.env.PORT) || 3000
app.ws.server.on 'connection', (socket, req) ->
  socket.brokerReady = do ->
    try
      hk: await new Futu()
    catch err
      console.error 'futu login failed', err
      null
app.ws.use (ctx) ->
  ctx.websocket
    .on 'message', (msg) ->
      try
        await wsHandler ctx, JSON.parse msg.toString()
      catch err
        console.error 'ws message failed', err
    .on 'error', (err) ->
      console.error 'ws error', err
