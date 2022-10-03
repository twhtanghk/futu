import sys, os
sys.path.append(os.getcwd())

from futuClient import FutuClient
import simplejson as json
from paho.mqtt import client as mqtt

class Mqtt:
  def __init__(self, host='emqx', port=1883):
    def on_message(client, data, msg):
      if msg.topic == 'stock':
        msg = json.loads(msg.payload)
        if msg['action'] == 'subscribe':
          self.monitor = msg['data']
    def on_connect(client, data, flags, rc):
      if rc == 0:
        print('mqtt connected')
        client.subscribe('stock/#')
        client.on_message = on_message
      else:
        raise IOError("return code %d\n", rc)
    self.futuClient = FutuClient()
    self.monitor = []
    self.client = mqtt.Client('futu')
    self.client.on_connect = on_connect
    self.client.connect(host, port)
    self.client.loop_start()

mqtt = Mqtt()

import schedule
import time

def quote():
  for code in mqtt.monitor:
    data = mqtt.futuClient.quote('HK.' + code)
    data['symbol'] = code
    data['src'] = 'aastocks'
    print(data)
    mqtt.client.publish('stock/aastocks', payload=json.dumps(data, ignore_nan=True))

schedule.every(5).minutes.do(quote)
while True:
  schedule.run_pending()
  time.sleep(1)
