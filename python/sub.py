import time
from futu import *

class OrderBook(OrderBookHandlerBase):
  def on_recv_rsp(self, res):
    ret_code, data = super.on_recv_rsp(res)
    if ret_code != RET_OK:
      print(data)
      return RET_ERROR, data
    return RET_OK, data

client = OpenQuoteContext(host='futu', port=11111)
handler = OrderBook()
client.set_handler(handler)
client.subscribe(['HK.00388'], [SubType.ORDER_BOOK])
time.sleep(60 * 60)
client.close()
