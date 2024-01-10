import moment from 'moment'
Futu = require('../index.coffee').default
import {Qot_Common} from 'futu-api/proto'
{KLType, QotMarket} = Qot_Common

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    futu = await new Futu host: 'localhost', port: 33333

    debug await futu.historyKL
      market: 'hk'
      code: '00700'
      start: moment '2023-02-01'
      end: moment '2023-02-02'
      freq: '5'
  catch err
    console.error err
