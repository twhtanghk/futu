from sys import argv
from futu import *

client = OpenQuoteContext(host='futu', port=11111)
ret, data = client.get_market_snapshot(argv[1:])
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
  data = data.filter(items=items)
  print(data.to_string())
else:
  print("error:", data)
client.close()
