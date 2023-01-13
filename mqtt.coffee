_ = require 'lodash'

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

symbols = []

subscribe = (list) ->
  old = symbols
  symbols
    .concat list
    .sort (a, b) ->
      a - b
  symbols = _.sortedUniq symbols
  client.emit 'symbols', symbols, old

unsubscribe = (list) ->
  old = client.symbols
  client.symbols = client.symbols
    .filter (code) ->
      code not in data
  client.emit 'symbols', client.symbols, old
