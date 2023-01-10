{Futu} = require '../index.coffee'

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    security =
      market: 1
      code: '00700'
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
  catch err
    console.error err
