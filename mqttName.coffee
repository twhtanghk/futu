{Futu} = require './index'

futu = await new Futu host: 'localhost', port: 33333

client = require 'mqtt'
  .connect process.env.MQTTURL,
    username: 'name'
    clientId: 'name'
    clean: false
  .on 'connect', ->
    client.subscribe "stock/name", qos: 2
    console.debug 'mqtt connected'
  .on 'message', (topic, msg) ->
    if topic == 'stock/name'
      list = JSON.parse msg.toString()
        .map (security) ->
          security.market = 1
          security
      try
        client.publish 'stock/name/data', JSON.stringify await futu.marketState list
      catch err
        client.publish 'stock/name/data', JSON.stringify error: err
  .on 'error', console.error
