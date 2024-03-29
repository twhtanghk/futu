_ = require 'lodash'
{Model} = require('model').default
import Futu from 'rxfutu'
{QotMarket, OrderStatus} = Futu.constant

class Rest extends Model
  constructor: (opts = {}) ->
    super _.defaults opts, baseUrl: '/api'

  name: (opts) ->
    {market, code} = opts
    opts.market ?= 'hk'
    await @read data: _.extend id: 'name', opts

  level: ({market, code}) ->
    await @read data: _.extend id: 'level', {market, code}

  getName: (opts) ->
    {code} = opts
    [{security, name}, ...] = await @name opts
    if security.code == code
      name

  getQuote: (opts) ->
    {market, code} = opts
    await @read data: _.extend id: 'quote', opts

  getHistory: (opts) ->
    {rehabType, klType, security, beginTime, endTime} = opts
    {security, klList} = await @read data: _.extend id: 'candle', opts
        
  history: (opts) ->
    (await @read data: _.extend id: 'history', opts).map (i) ->
      i.time = i.timestamp
      i

  getOptionChain: (opts) ->
    {market, code, min, max, beginTime, endTime} = opts
    await @read data: _.extend id: 'optionChain', opts

  getPosition: (opts) ->
    await @read data: _.extend id: 'position', opts

  getDeal: (opts) ->
    await @read data: _.extend id: 'deal', opts

export default new Rest()
