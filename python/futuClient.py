from futu import *

class FutuClient:
  def __init__(self):
    self.client = OpenQuoteContext(host='futu', port=11111)

  def __del__(self):
    self.client.close()

  def basic(self, symbol):
    ret, data = self.client.get_stock_basicinfo(Market.HK, SecurityType.STOCK, [symbol])
    if ret == RET_OK:
      return data
    else:
      raise IOError(data)

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
      'last_price': 'close',
      'open_price': 'open',
      'high_price': 'high',
      'low_price': 'low',
      'pe_ratio': 'pe',
      'pb_ratio': 'pb',
      'net_asset_per_share': 'nav',
      'dividend_ratio_ttm': 'yield_percentage'
    }
    if ret == RET_OK:
      ret = data.iloc[0].filter(items=items).rename(index=columns).to_dict()
      change = ret['close'] - ret['prev_close_price']
      ret['quote'] = {
        'change': [ round(change, 2), round(change / ret['close'] * 100, 2) ],
        'curr': ret['close'],
        'high': ret['high'],
        'last': ret['prev_close_price'],
        'low': ret['low']
      }
      ret['details'] = {
        'pb': ret['pb'],
        'pe': ret['pe']
      }
      ret['name'] = self.basic(symbol).iloc[0]['name']
      return ret
    else:
      raise IOError(data)
