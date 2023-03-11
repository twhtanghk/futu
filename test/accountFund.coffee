{Futu} = require '../index'
{TrdEnv} = require('../backend/futu').default

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    futu = await new Futu host: 'localhost', port: 33333

    debug await futu.accountFund trdEnv: TrdEnv.TrdEnv_Simulate
  catch err
    console.error err
