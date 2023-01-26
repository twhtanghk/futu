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
          subscribe data
        when 'unsubcribe'
          unsubscribe data
  .on 'error', console.error

symbols = []

subscribe = (list) ->
  old = symbols
  symbols = symbols
    .concat list
    .sort (a, b) ->
      a - b
  symbols = _.sortedUniq symbols
  console.log symbols
  await futu.subscribe symbols
  client.emit 'symbols', symbols, old

unsubscribe = (list) ->
  old = client.symbols
  symbols = symbols
    .filter (code) ->
      code not in data
  client.emit 'symbols', symbols, old

futu.on '1', (quote) ->
  {code, timestamp, high, low, open, close, volume, turnover} = quote
  src = 'aastocks'
  symbol = code
  lastUpdatedAt = timestamp
  console.log {src, symbol, high, low, open, close, volume, turnover}
  client.publish 'stock/aastocks', JSON.stringify {src, symbol, high, low, open, close, volume, turnover}
