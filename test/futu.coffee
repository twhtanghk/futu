{Futu} = require '../index.coffee'
import {Qot_Common} from 'futu-api/proto'

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    security =
      market: 1
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
    debug await futu.subInfo()
    {SubType, QotMarket} = Qot_Common
    req =
      c2s:
        securityList: securityList
        subTypeList: [SubType.SubType_Basic]
        isSUbOrUnSub: true
        isRegOrUnRegPush: true
    futu.ws.onPush = (cmd, res) ->
      {retType, s2c} = res
      debug s2c
    debug await futu.ws.Sub req
  catch err
    console.error err
