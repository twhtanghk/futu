#!/usr/bin/env python

from futu import *

client = OpenSecTradeContext(filter_trdmarket=TrdMarket.HK, host='localhost', port=11111, security_firm=SecurityFirm.FUTUSECURITIES)
ret, data = client.history_order_list_query()
if ret == RET_OK:
  status = ['FILLED_ALL']
  print(data[data['order_status'].isin(status)].to_string())
else:
  print("error:", data)
client.close()
