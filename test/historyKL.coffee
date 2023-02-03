{Futu} = require '../index.coffee'
import {Qot_Common} from 'futu-api/proto'
{KLType, QotMarket} = Qot_Common

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    futu = await new Futu host: 'localhost', port: 33333

    debug await futu.historyKL
      security:
        market: QotMarket.QotMarket_HK_Security
        code: '00700'
      beginTime: '2023-02-01'
      endTime: '2023-02-02'
      klType: KLType.KLType_10Min
  catch err
    console.error err
