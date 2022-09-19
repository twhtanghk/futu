#!/usr/bin/env python

from sys import argv
from futu import *

client = OpenQuoteContext(host='localhost', port=11111)
ret, data = client.get_option_expiration_date(code=argv[1])
if ret == RET_OK:
  strike_time = data.iloc[0]['strike_time']
  filter = OptionDataFilter()
  filter.delta_min = 0
  filter.delta_max = 0.1
  ret, data = client.get_option_chain(code=argv[1], start=strike_time, end=strike_time, option_cond_type=OptionCondType.WITHIN)
  if ret == RET_OK:
    print(data.to_string())
  else:
    print("error:", data)
else:
  print("error:", data)
client.close()
