_ = require 'lodash'
Futu = require('../index').default
subType = 
  '1': Futu.constant.SubType.SubType_KL_1Min
  '5': Futu.constant.SubType.SubType_KL_5Min
  '15': Futu.constant.SubType.SubType_KL_15Min

module.exports = (ctx, msg) ->
  {action, subtype, market, code, interval} = msg
  try
    switch action
      when 'subscribeAcc'
        await ctx.api.subscribeAcc()
      when 'subscribe'
        if interval in ['1', '5', '15']
          subtype = subType[interval]
        await ctx.api.subscribe 
          market: market
          code: code
          subtype: subtype
      when 'unsubscribe'
        if interval in ['1', '5', '15']
          subtype = subType[interval]
        await ctx.api.unsubscribe 
          market: market
          code: code
          subtype: subtype
  catch err
    console.error err
  ctx.api
    .on 'candle', (data) ->
      ctx.websocket.send JSON.stringify topic: 'candle', data: data
    .on 'orderBook', (data) ->
      ctx.websocket.send JSON.stringify topic: 'orderBook', data: data
    .on 'trdUpdate', (data) ->
      ctx.websocket.send JSON.stringify topic: 'trdUpdate', data: data
