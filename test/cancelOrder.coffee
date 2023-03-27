{Futu} = require '../index'

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    futu = await new Futu host: 'localhost', port: 33333

    debug process.argv
    debug await futu.cancelOrder id: process.argv[2]
  catch err
    console.error err
