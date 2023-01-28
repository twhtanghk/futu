{Futu} = require '../index.coffee'
import {Qot_Common} from 'futu-api/proto'
{QotMarket} = Qot_Common

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    futu = await new Futu host: 'localhost', port: 33333

    debug await futu.historyKL
      security:
        market: QotMarket.QotMarket_HK_Security
        code: '00700'
  catch err
    console.error err
