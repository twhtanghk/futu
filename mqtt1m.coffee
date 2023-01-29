_ = require 'lodash'
{Futu} = require './index'
{Qot_Common} = require 'futu-api/proto'
{SubType} = Qot_Common

futu = (await new Futu host: 'localhost', port: 33333).on '1', (quote) ->
  {code, timestamp, high, low, open, close, volume, turnover} = quote
  src = 'aastocks'
  symbol = code
  lastUpdatedAt = timestamp
  msg = {src, symbol, lastUpdatedAt, high, low, open, close, volume, turnover}
  client.publish 'stock/aastocks', JSON.stringify msg

subtype =
  '1': SubType.SubType_KL_1Min
  '5': SubType.SubType_KL_5Min
  '15': SubType.SubType_KL_15Min

client = require 'mqtt'
  .connect process.env.MQTTURL,
    username: 'realtime'
    clientId: 'realtime'
    clean: false
  .on 'connect', ->
    client.subscribe "stock/#", qos: 2
    console.debug 'mqtt connected'
  .on 'message', (topic, msg) ->
    msg = JSON.parse msg.toString()
    switch topic
      when 'stock/subscribe'
        {code, interval} = msg
        if interval in ['1', '5', '15']
          await futu.subscribe code, subtype[interval]
      when 'stock/unsubcribe'
        {code, interval} = msg
        if interval in ['1', '5', '15']
          await futu.unsubscribe code, subType[interval]
  .on 'error', console.error
