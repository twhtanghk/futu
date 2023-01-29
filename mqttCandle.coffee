{Futu} = require './index'

futu = await new Futu host: 'localhost', port: 33333

opts =
  url: process.env.MQTTURL
  user: process.env.MQTTUSER
  client: 'candle'

client = require 'mqtt'
  .connect opts.url,
    username: opts.user
    clientId: opts.client
    clean: false
  .on 'connect', ->
    client.subscribe "stock/candle", qos: 2
    console.debug 'mqtt connected'
  .on 'message', (topic, msg) ->
    if topic == 'stock/candle'
      {code} = JSON.parse msg.toString()
      security =
        market: 1
        code: code
      try
        client.publish 'stock/candle/data', JSON.stringify await futu.historyKL {security}
      catch err
        console.error err
  .on 'error', console.error
