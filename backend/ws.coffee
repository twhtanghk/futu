_ = require 'lodash'
futu = require('./futu').default
subType = 
  '1': futu.SubType.SubType_KL_1Min
  '5': futu.SubType.SubType_KL_5Min
  '15': futu.SubType.SubType_KL_15Min

module.exports = (ctx, msg) ->
  ctx.session.subscribed ?= []
  {action, code, interval} = msg
  switch action
    when 'subscribe'
      if interval in ['1', '5', '15']
        ctx.session.subscribed.push {code, interval}
        try
          await ctx.api.subscribe code, subType[interval]
        catch err
          console.error err
    when 'unsubscribe'
      if interval in ['1', '5', '15']
        ctx.session.subscribed = _.filter ctx.session.subscribed, (i) ->
          not (i.code == code and i.interval == interval)
        try
          await ctx.api.unsubscribe code, subType[interval]
        catch err
          console.error err
  ctx.api
    .on '1', (quote) ->
      found = _.find ctx.session.subscribed, {code: quote.code, interval: '1'}
      if found?
        ctx.websocket.send JSON.stringify interval: '1', quote: quote
    .on '5', (quote) ->
      found = _.find ctx.session.subscribed, {code: quote.code, interval: '5'}
      if found?
        ctx.websocket.send JSON.stringify interval: '5', quote: quote
    .on '15', (quote) ->
      found = _.find ctx.session.subscribed, {code: quote.code, interval: '15'}
      if found?
        ctx.websocket.send JSON.stringify interval: '15', quote: quote
