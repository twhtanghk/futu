{Futu, levels} = require '../index.coffee'
import {Qot_Common} from 'futu-api/proto'
{KLType, QotMarket} = Qot_Common

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    futu = await new Futu host: 'localhost', port: 33333

    df = await futu.historyKL
      security:
        market: QotMarket.QotMarket_HK_Security
        code: '00700'
      beginTime: '2023-05-12'
      endTime: '2023-11-11'
      klType: KLType.KLType_Day
    debug levels df.klList
  catch err
    console.error err
