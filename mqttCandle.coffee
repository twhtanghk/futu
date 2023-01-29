{Futu} = require './index'
{Qot_Common} = require 'futu-api/proto'
{KLType} = Qot_Common

futu = await new Futu host: 'localhost', port: 33333

kltype =
  '1': KLType.KLType_1Min
  '5': KLType.KLType_5Min
  '15': KLType.KLType_15Min
  '30': KLType.KLType_30Min
  '1h': KLType.KLType_60Min
  '1d': KLType.KLType_Day
  '1w': KLType.KLType_Week
  '1m': KLType.KLType_Month
  '1y': KLType.KLType_Year

client = require 'mqtt'
  .connect process.env.MQTTURL,
    username: 'candle'
    clientId: 'candle'
    clean: false
  .on 'connect', ->
    client.subscribe "stock/candle", qos: 2
    console.debug 'mqtt connected'
  .on 'message', (topic, msg) ->
    if topic == 'stock/candle'
      {code, interval} = JSON.parse msg.toString()
      security =
        market: 1
        code: code
      try
        client.publish 'stock/candle/data', JSON.stringify await futu.historyKL {security, klType: kltype[interval]}
      catch err
        console.error err
  .on 'error', console.error
