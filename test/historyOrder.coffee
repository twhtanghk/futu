moment = require 'moment'
{Futu} = require '../index'

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    futu = await new Futu host: 'localhost', port: 33333

    beginTime = moment()
      .subtract day: 3
      .format 'YYYY-MM-DD HH:mm:ss'
    debug await futu.historyOrder {beginTime}
  catch err
    console.error err
