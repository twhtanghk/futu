Futu = require('../index').default

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    futu = await new Futu()

    debug await (await futu.accounts())[0].position()
  catch err
    console.error err
