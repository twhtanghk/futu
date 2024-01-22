Futu = require('../index').default

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    futu = await new Futu()

    debug await futu.accounts()
  catch err
    console.error err
