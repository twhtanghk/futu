from futu import *
import hug

class Client:
  def __init__(self):
    self.client = OpenQuoteContext(host='futu', port=11111)

  def __del__(self):
    self.client.close()

  def quote(self, symbol):
    ret, data = self.client.get_market_snapshot(symbol)
    items=[
      'code',
      'update_time', 
      'last_price', 
      'open_price', 
      'high_price', 
      'low_price', 
      'prev_close_price', 
      'volume', 
      'turnover', 
      'turnover_rate'
    ]
    if ret == RET_OK:
      return data.filter(items=items)
    else:
      raise IOError(data)

class Futu:
  def __init__(self):
    self.client = Client()

  @hug.object.get('/quote')
  def quote(self, **kwargs):
    print(kwargs['symbol'])
    return

  @hug.object.get('/{file}', output=hug.output_format.file)
  def static(self, file):
    return 'static/{}'.format(file)

route = hug.route.API(__name__)
route.object('/')(Futu)
