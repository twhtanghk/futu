_ = require 'lodash'

module.exports = (ctx, msg) ->
  ctx.session.subscribed ?= []
  {action, code, interval} = msg
  switch action
    when 'subscribe'
      if interval in ['1', '5', '15']
        ctx.session.subscribed.push {code, interval}
        await ctx.api.subscribe code, subType[interval]
    when 'unsubscribe'
      if interval in ['1', '5', '15']
        ctx.session.subscribed = _.filter ctx.session.subscribed, (i) ->
          not (i.code == code and i.interval == interval)
        await ctx.api.unsubscribe code, subType[interval]
  ctx.api
    .on '1', (quote) ->
      found = _.find ctx.session.subscribed, {code: quote.code, interval: '1'}
      if found?
        ctx.websocket.send quote
    .on '5', (quote) ->
      found = _.find ctx.session.subscribed, {code: quote.code, interval: '5'}
      if found?
        ctx.websocket.send quote
    .on '15', (quote) ->
      found = _.find ctx.session.subscribed, {code: quote.code, interval: '15'}
      if found?
        ctx.websocket.send quote
