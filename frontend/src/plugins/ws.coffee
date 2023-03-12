_ = require 'lodash'
import * as Promise from 'bluebird'
import ReconnectingWebSocket from 'reconnecting-websocket'

class WS extends ReconnectingWebSocket
  constructor: (url, protocol) ->
    super url, protocol

  send: (obj) ->
    super JSON.stringify obj
    @

  subscribeAcc: (opts) ->
    @send _.extend action: 'subscribeAcc', opts

  subscribe: (opts) ->
    {subtype, market, code, interval} = opts
    @send _.extend action: 'subscribe', opts

  unsubscribe: (opts) ->
    {subtype, market, code, interval} = opts
    @send _.extend action: 'unsubscribe', opts

  on: (topic, func) ->
    @addEventListener topic, (event) ->
      func JSON.parse event.data
    @

export default new Promise (resolve, reject) ->
  #ws = new WS 'ws://172.19.0.8:3000'
  ws = new WS "ws://#{location.host}"
  ws.addEventListener 'error', console.error
  ws.addEventListener 'open', ->
    resolve ws
