_ = require 'lodash'
import * as Promise from 'bluebird'
import ReconnectingWebSocket from 'reconnecting-websocket'
import {default as Futu} from '../../../index'
{QotMarket, OrderStatus} = Futu

class WS extends ReconnectingWebSocket
  constructor: (url, protocol) ->
    super url, protocol

  send: (obj) ->
    super JSON.stringify obj
    @

  subscribeAcc: (opts) ->
    @send _.extend action: 'subscribeAcc', opts

  subscribe: (opts) ->
    opts.market ?= QotMarket.QotMarket_HK_Security
    @send _.extend action: 'subscribe', opts

  unsubscribe: (opts) ->
    opts.market ?= QotMarket.QotMarket_HK_Security
    @send _.extend action: 'unsubscribe', opts

  ohlc: (opts) ->
    opts.market ?= 'hk'
    @send _.extend action: 'ohlc', opts
    
  # loop for all constituent stocks of specified index
  # get dataSize of ohlc data
  # calculate mean and stdev for every chunkSize of data
  # check if last close fall outside +-n * stdev of last element
  constituent: (opts={}) ->
    opts.idx ?= 'HSI Constituent'
    opts.dataSize ?= month: 6
    opts.chunkSize ?= 20
    opts.n ?= 2
    @send _.extend action: 'constituent', opts

  on: (topic, func) ->
    @addEventListener topic, (event) ->
      func JSON.parse event.data
    @

  addListener: (event, handler) ->
    @addEventListener event, handler

export default new Promise (resolve, reject) ->
  ws = new WS "ws://#{location.host}"
  ws.addEventListener 'error', console.error
  ws.addEventListener 'open', ->
    resolve ws
