_ = require 'lodash'
futu = require('./futu').default
subType = 
  '1': futu.SubType.SubType_KL_1Min
  '5': futu.SubType.SubType_KL_5Min
  '15': futu.SubType.SubType_KL_15Min

module.exports = (ctx, msg) ->
  ctx.session.subscribed ?= []
  {action, market, code, interval} = msg
  switch action
    when 'subscribe'
      if interval in ['1', '5', '15']
        ctx.session.subscribed.push {code, interval}
        try
          await ctx.api.subscribe 
            market: market
            code: code
            subtype: subType[interval]
        catch err
          console.error err
    when 'unsubscribe'
      if interval in ['1', '5', '15']
        ctx.session.subscribed = _.filter ctx.session.subscribed, (i) ->
          not (i.code == code and i.interval == interval)
        try
          await ctx.api.unsubscribe 
            market: market
            code: code
            subtype: subType[interval]
        catch err
          console.error err
  ctx.api
    .on 'candle', (quote) ->
      found = _.find ctx.session.subscribed, (i) ->
        i.code == quote.code and 'interval' of i
      if found?
        ctx.websocket.send JSON.stringify interval: found.interval, quote: quote
    .on 'orderBook', (quote) ->
      found = _.find ctx.session.subscribed, (i) ->
        i.code == quote.code and 'orderBook' of 'i'
      if found?
        ctx.websocket.send JSON.stringify orderBook: found.orderBook, quote: quote
