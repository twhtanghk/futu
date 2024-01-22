moment = require 'moment'
Futu = require('../index').default

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    futu = await new Futu host: 'localhost', port: 33333

    start = moment()
      .subtract year: 3
    debug await (await futu.accounts())[0].historyOrder {start}
  catch err
    console.error err
