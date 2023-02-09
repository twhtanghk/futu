{Futu} = require '../index.coffee'

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    futu = await new Futu host: 'localhost', port: 33333

    debug (await futu.plateSecurity market: 1, code: 'HSI Constituent').map (i) ->
        i.basic.security.code
  catch err
    console.error err
