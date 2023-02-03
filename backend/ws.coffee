_ = require 'lodash'
futu = require('./futu').default
subType = 
  '1': futu.SubType.SubType_KL_1Min
  '5': futu.SubType.SubType_KL_5Min
  '15': futu.SubType.SubType_KL_15Min

module.exports = (ctx, msg) ->
  {action, subtype, market, code, interval} = msg
  switch action
    when 'subscribe'
      if interval in ['1', '5', '15']
        subtype = subType[interval]
      try
        await ctx.api.subscribe 
          market: market
          code: code
          subtype: subtype
      catch err
        console.error err
    when 'unsubscribe'
      if interval in ['1', '5', '15']
        subtype = subType[interval]
      try
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
