opts =
  url: process.env.VUE_APP_MQTTURL
  user: process.env.VUE_APP_MQTTUSER
  client: process.env.VUE_APP_MQTTCLIENT

client = require 'mqtt'
  .connect opts.url,
    username: opts.user
    clientId: opts.client
    clean: false
  .on 'connect', ->
    client.subscribe "stock/#", qos: 2
    console.debug 'mqtt connected'
  .on 'error', console.error
        
export default client
