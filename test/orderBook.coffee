{Futu} = require '../index.coffee'
futu = require('../backend/futu').default

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    api = (await new Futu host: 'localhost', port: 33333)
      .on 'orderBook', (data) ->
        {orderBookBidList, orderBookAskList} = data
        [bid, ...] = orderBookBidList
        [ask, ...] = orderBookAskList
        debug {ask, bid}

    await api.subscribe
      market: futu.QotMarket.QotMarket_HK_Security
      code: 'BYD230227C270000'
      subtype: futu.SubType.SubType_OrderBook
  catch err
    console.error err
