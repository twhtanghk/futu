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
      'turnover_rate',
      'pe_ratio',
      'pb_ratio',
      'net_asset_per_share',
      'dividend_ratio_ttm'
    ]
    columns = {
      'code': 'symbol',
      'update_time': 'lastUpdatedAt',
      'last_price': 'quote',
      'open_price': 'open',
      'high_price': 'high',
      'low_price': 'low',
      'pe_ratio': 'pe',
      'pb_ratio': 'pb',
      'net_asset_per_share': 'nav',
      'dividend_ratio_ttm': 'yield_percentage'
    }
    if ret == RET_OK:
      return data.iloc[0].filter(items=items).rename(index=columns).to_dict()
    else:
      raise IOError(data)

class Futu:
  def __init__(self):
    self.client = Client()

  @hug.object.get('/quote')
  def quote(self, **kwargs):
    ret = []
    for i in kwargs['symbol']:
      ret.append(self.client.quote(i))
    return ret

  @hug.object.get('/{file}', output=hug.output_format.file)
  def static(self, file):
    return 'static/{}'.format(file)

route = hug.route.API(__name__)
route.object('/')(Futu)
