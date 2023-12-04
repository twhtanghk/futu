{Futu} = require '../index.coffee'

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    futu = await new Futu host: 'localhost', port: 33333

    await futu.subscribe code: '00700'
    futu.on 'candle', ->
      debug "candle debug #{JSON.stringify arguments, null, 2}"
  catch err
    console.error err
