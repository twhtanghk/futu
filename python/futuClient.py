from futu import *

class FutuClient:
  def __init__(self):
    self.client = OpenQuoteContext(host='futu', port=11111)

  def __del__(self):
    self.client.close()

  def basic(self, symbol):
    ret, data = self.client.get_stock_basicinfo(Market.HK, SecurityType.STOCK, symbol)
    if ret == RET_OK:
      return data
    else:
      raise IOError(data)

  def quoteDetails(self, symbol):
    ret, data = self.client.get_market_snapshot(symbol)
    if ret == RET_OK:
      return data
    else:
      raise IOError(data)

  def quote(self, symbol):
    data = self.quoteDetails(symbol)
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
    ret = data.filter(items=items).rename(columns=columns)
    ret['change'] = round(ret['close'] - ret['prev_close_price'], 2)
    ret['changePercent'] = round(ret['change'] / ret['prev_close_price'] * 100, 2)
    ret['curr'] = ret['close']
    ret['last'] = ret['prev_close_price']
    return ret

import unittest

class TestFutuClient(unittest.TestCase):
  def test_basic(self):
    try:
      client = FutuClient()
      print(client.basic(['HK.00005']).to_string())
    except:
      self.fail('unexpected exception')

  def test_quoteDetails(self):
    try:
      client = FutuClient()
      print(client.quoteDetails(['HK.00005']).to_string())
    except:
      self.fail('unexpected exception')

  def test_quote(self):
    try:
      client = FutuClient()
      print(client.quote(['HK.00005']).to_string())
    except:
      self.fail('unexpected exception')
