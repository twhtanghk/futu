{Futu} = require '../index.coffee'
import moment from 'moment'
import {Qot_Common} from 'futu-api/proto'
{KLType, QotMarket} = Qot_Common
{KLType_1Min} = KLType

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
    debug await futu.historyKL {security}
    debug await futu.plateSet market: 1

    debug await futu.subscribe ['00700', '00388', '01211', '800000']
    futu.on '1', debug
    debug await futu.subInfo()

    await new Promise (resolve) ->
      setTimeout resolve, 60000
    debug await futu.unsubscribe '00700'
    debug await futu.subInfo()

    await new Promise (resolve) ->
      setTimeout resolve, 60000
    debug await futu.unsubscribe()
    debug await futu.subInfo()

    beginTime = moment()
      .add month: 1
      .startOf 'Month'
      .format 'YYYY-MM-DD'
    endTime = moment()
      .add month: 1
      .endOf 'Month'
      .format 'YYYY-MM-DD'
    debug await futu.optionChain {code: '00700', strikeRange: [390, 420], beginTime, beginTime, endTime: endTime}
  catch err
    console.error err
