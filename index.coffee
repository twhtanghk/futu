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
      
  # basic data
  marketState: ({securityList}={}) ->
    await @ws.GetMarketState c2s: {securityList}

  capitalFlow: ({security}) ->
    await @ws.GetCapitalFlow c2s: {security}

  capitalDistribution: ({security}) ->
    await @ws.GetCapitalDistribution c2s: {security}

  ownerPlate: ({securityList}) ->
    await @ws.GetOwnerPlate c2s: {securityList}

  historyKL: ({rehabType, klType, security, beginTime, endTime}) ->
    await @ws.RequestHistoryKL c2s: {rehabType, klType, security, beginTime, endTime}

  plateSet: ({market, placeSetType}={}) ->
    opts = _.defaults {market, placeSetType}, placeSetType: 0
    await @ws.GetPlateSet c2s: opts

  subInfo: ({isReqAllConn}={}) ->
    await @ws.GetSubInfo c2s: _.defaults {isReqAllConn}, isReqAllConn: true

module.exports =
  Futu: Futu
