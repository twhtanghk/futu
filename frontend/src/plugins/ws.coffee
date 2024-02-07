_ = require 'lodash'
import * as Promise from 'bluebird'
import {default as Futu} from 'rxfutu'
import {WebSocketSubject} from 'rxjs/webSocket'

class WS extends WebSocketSubject
  constructor: (url) ->
    super url, deserializer: ({data}) -> JSON.parse data

  next: (opts) ->
    super JSON.stringify _.extend url: document.URL, opts
    @

  subMarket: (opts) ->
    opts.market ?= 'hk'
    @next _.extend action: 'subMarket', opts

  unsubMarket: (opts) ->
    @next _.extend action: 'unsubMarket', opts

  subKL: (opts) ->
    opts.market ?= 'hk'
    @next _.extend action: 'subKL', opts

  unsubKL: (opts) ->
    opts.market ?= 'hk'
    @next _.extend action: 'unsubKL', opts

  orderBook: (opts) ->
    @next _.extend action: 'orderBook', opts

  unsubOrderBook: (opts) ->
    opts.market ?= 'hk'
    @next _.extend action: 'unsubOrderBook', opts

  ohlc: (opts) ->
    opts.market ?= 'hk'
    @next _.extend action: 'ohlc', opts
    
  # loop for all constituent stocks of specified index
  # get dataSize of ohlc data
  # calculate mean and stdev for every chunkSize of data
  # check if last close fall outside +-n * stdev of last element
  constituent: (opts={}) ->
    opts.idx ?= 'HSI Constituent'
    opts.dataSize ?= month: 6
    opts.chunkSize ?= 20
    opts.n ?= 2
    @next _.extend action: 'constituent', opts

export default new WS "ws://#{location.host}"
