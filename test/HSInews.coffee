{Futu} = require '../index.coffee'
{HKEXNew} = require 'hkex'

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    futu = await new Futu host: 'localhost', port: 33333

    hsi = (await futu.plateSecurity market: 1, code: 'HSI Constituent')
      .map (i) ->
        i.basic.security.code
    console.log hsi
    hkexnews = new HKEXNew()
    for await i from hkexnews.iter()
      if i.code in hsi
        console.log i
    
  catch err
    console.error err
