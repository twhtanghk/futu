moment = require 'moment'
Futu = require('../index').default
strategy = require('algotrader/strategy').default

try
  broker = await new Futu host: 'localhost', port: 33333
  [..., method, code, low, high] = process.argv
  low = parseInt low
  high = parseFloat high
  {g, destroy} = await broker.dataKL
    market: 'hk'
    code: code
    start: moment().subtract 1, 'week'
    freq: '1'
  for await i from strategy[method] g, {low, high}
    i.time = new Date i.time * 1000
    if process.env.DEBUG or 'entryExit' of i
      i.timestamp = new Date i.timestamp * 1000
      console.log JSON.stringify i, null, 2
catch err
  console.error err
