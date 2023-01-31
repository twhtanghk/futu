Koa = require 'koa'
logger = require 'koa-logger'
bodyParser = require 'koa-bodyparser'
methodOverride = require 'koa-methodoverride'
cors = require '@koa/cors'
router = require './router'
serve = require 'koa-static'

app = new Koa()
app.keys = process.env.KEYS?.split(',') || ['keep it secret']
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
