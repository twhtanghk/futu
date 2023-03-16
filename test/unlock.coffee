md5 = require 'md5'
{Futu} = require '../index'

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    futu = await new Futu host: 'localhost', port: 33333

    debug await futu.unlock pwdMD5: md5 'passwd'
  catch err
    console.error err
