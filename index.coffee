import ftWebsocket from 'futu-api'
global.WebSocket = require 'ws'

ws = new ftWebsocket()
ws.start 'futuopend', 11112, false, null
ws.onlogin = ->
  msg = c2s: securityList: [{market: 1, code: '00700'}]
  console.log JSON.stringify await ws.GetMarketState msg
  console.log await ws.GetSubInfo c2s: isReqAllConn: true
