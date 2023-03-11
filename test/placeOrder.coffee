{Futu} = require '../index'
{TrdSide} = require('../backend/futu').default

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    futu = await new Futu host: 'localhost', port: 33333

    debug await futu.placeOrder
      trdSide: TrdSide.TrdSide_Buy
      code: '00700'
      qty: 100
      price: 333

  catch err
    console.error err
