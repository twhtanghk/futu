{Futu} = require '../index.coffee'

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

# 非传统/可再生能�
# node -r coffeescript/register -r esm test/plateSecurity.coffee BK1016
do ->
  try 
    futu = await new Futu host: 'localhost', port: 33333

    debug (await futu.plateSecurity market: 1, code: process.argv[2] || 'HSI Constituent').map (i) ->
        i.basic.security.code
  catch err
    console.error err
