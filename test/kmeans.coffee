{Futu} = require '../index.coffee'
import {Qot_Common} from 'futu-api/proto'
{KLType, QotMarket} = Qot_Common
skmeans = require 'skmeans'
moment = require 'moment'

debug = (obj) ->
  console.error JSON.stringify obj, null, 2

do ->
  try 
    futu = await new Futu host: 'localhost', port: 33333

    data = await futu.historyKL
      security:
        market: QotMarket.QotMarket_HK_Security
        code: process.argv[2] || '00700'
      endTime: moment()
        .format 'YYYY-MM-DD'
      beginTime: moment()
        .subtract month: 3
        .format 'YYYY-MM-DD'
      klType: KLType.KLType_Day
    price = data.klList.map ({close}) ->
      close
    debug skmeans(price, 2).centroids
  catch err
    console.error err
