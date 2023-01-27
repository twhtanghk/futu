_ = require 'lodash'
{Futu} = require './index'

futu = await new Futu host: 'localhost', port: 33333

mqtt =
  url: process.env.MQTTURL
  user: process.env.MQTTUSER
  client: process.env.MQTTCLIENT
  topic: process.env.MQTTTOPIC

client = require 'mqtt'
  .connect mqtt.url,
    username: mqtt.user
    clientId: mqtt.client
    clean: false
  .on 'connect', ->
    client.subscribe "#{mqtt.topic}/#", qos: 2
    console.debug 'mqtt connected'
  .on 'message', (topic, msg) ->
    if topic == mqtt.topic
      msg = JSON.parse msg.toString()
      {action, data} = msg
      switch action
        when 'subscribe'
          await futu.subscribe data
        when 'unsubcribe'
          await futu.unsubscribe data
  .on 'error', console.error

futu.on '1', (quote) ->
  {code, timestamp, high, low, open, close, volume, turnover} = quote
  src = 'aastocks'
  symbol = code
  lastUpdatedAt = timestamp
  msg = {src, symbol, lastUpdatedAt, high, low, open, close, volume, turnover}
  console.log msg
  client.publish 'stock/aastocks', JSON.stringify msg
