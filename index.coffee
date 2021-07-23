import ftWebsocket from 'futu-api'
_ = require 'lodash'
Promise = require 'bluebird'
global.WebSocket = require 'ws'

class Futu
  constructor: ({host, port}) ->
    return do =>
      await new Promise (resolve, reject) =>
        @ws = new ftWebsocket()
        @ws.start host, port, false, null
        @ws.onlogin = resolve
      @
      
  plateSet: ({market, placeSetType}={}) ->
    opts = _.defaults {market, placeSetType}, placeSetType: 0
    await @ws.GetPlateSet c2s: opts

  marketState: ({securityList}={}) ->
    await @ws.GetMarketState c2s: {securityList}

  subInfo: ({isReqAllConn}={}) ->
    await @ws.GetSubInfo c2s: _.defaults {isReqAllConn}, isReqAllConn: true

module.exports =
  Futu: Futu
