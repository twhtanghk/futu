{Futu} = require '../index.coffee'

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    futu = await new Futu host: 'localhost', port: 33333

    debug await futu.basicQuote code: '00700'
  catch err
    console.error err