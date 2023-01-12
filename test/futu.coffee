{Futu} = require '../index.coffee'
import {Qot_Common} from 'futu-api/proto'
{QotMarket} = Qot_Common

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    security =
      market: QotMarket.QotMarket_HK_Security
      code: '00700'
    securityList = [security]
    futu = await new Futu host: 'localhost', port: 33333
    debug await futu.marketState securityList: [security]
    debug await futu.capitalFlow {security}
    debug await futu.capitalDistribution {security}
    debug await futu.ownerPlate securityList: [security]
    debug await futu.historyKL 
      rehabType: 1
      klType: 2
      security: security
      beginTime: '2021-01-01'
      endTime: '2021-06-30'
    debug await futu.plateSet market: 1
    debug await futu.subscribe ['00700', '00388']
    debug await futu.subInfo()
  catch err
    console.error err
