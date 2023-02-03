import * as Promise from 'bluebird'

export default new Promise (resolve, reject) ->
  ws = new WebSocket 'ws://172.19.0.8:3000'
  #ws = new WebSocket "ws://#{location.host}"
  ws.addEventListener 'error', console.error
  ws.addEventListener 'open', ->
    resolve ws
