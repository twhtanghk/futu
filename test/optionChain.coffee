{Futu} = require '../index.coffee'
futu = require('../backend/futu').default

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    api = (await new Futu host: 'localhost', port: 33333)

    debug await api.optionChain
      code: '00700'
      strikeRange: [330, 350]
  catch err
    console.error err
