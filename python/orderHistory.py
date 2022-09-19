from futu import *

client = OpenSecTradeContext(filter_trdmarket=TrdMarket.HK, host='futu', port=11111, security_firm=SecurityFirm.FUTUSECURITIES)
ret, data = client.history_order_list_query()
if ret == RET_OK:
  print(data.to_string())
else:
  print("error:", data)
client.close()
