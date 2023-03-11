_ = require 'lodash'
{Model} = require('model').default

class Trade extends Model
  constructor: (opts = {}) ->
    super _.defaults opts, baseUrl: '/api/trade'

export default new Trade()
