_ = require 'lodash'
{Model} = require('model').default

class Rest extends Model
  constructor: (opts = {}) ->
    super _.defaults opts, baseUrl: '/api'

  getName: (opts) ->
    {market, code} = opts
    [{security, name}, ...] = await @read data: _.extend id: 'name', opts
    if security.code == code
      name

  getHistory: (opts) ->
    {rehabType, klType, security, beginTime, endTime} = opts
    {security, klList} = await @read data: _.extend id: 'candle', opts
        
  getOptionChain: (opts) ->
    {market, code, min, max, beginTime, endTime} = opts
    await @read data: _.extend id: 'optionChain', opts

export default new Rest()
