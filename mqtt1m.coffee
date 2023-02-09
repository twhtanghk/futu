_ = require 'lodash'
{Futu} = require './index'
futu = require('./backend/futu').default
{Qot_Common} = require 'futu-api/proto'
{SubType} = Qot_Common

api = (await new Futu host: 'localhost', port: 33333)
  .on 'candle', (quote) ->
    _.extend quote,
      src: 'aastocks'
      symbol: quote.code
      lastUpdatedAt: quote.timestamp
    client
      .publish 'stock/aastocks', JSON.stringify quote

client = require 'mqtt'
  .connect process.env.MQTTURL,
    username: 'realtime'
    clientId: 'realtime'
    clean: false
  .on 'connect', ->
    client.subscribe "stock/#", qos: 2
    console.debug 'mqtt connected'
  .on 'message', (topic, msg) ->
    if topic == 'stock'
      {action, data} = JSON.parse msg.toString()
      switch action
        when 'subscribe'
          data.map (code) ->
            await api.subscribe 
              market: futu.QotMarket.QotMarket_HK_Security
              code: code
        when 'unsubcribe'
          data.map (code) ->
            await api.unsubscribe 
              market: futu.QotMarket.QotMarket_HK_Security
              code: code
  .on 'error', console.error
