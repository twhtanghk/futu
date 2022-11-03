import sys, os
sys.path.append(os.getcwd())

from futuClient import FutuClient
from futu import *

class CurKline(CurKlineHandlerBase):
  def on_recv_rsp(self, res):
    ret_code, data = super(CurKline, self).on_recv_rsp(res)
    if ret_code != RET_OK:
      raise IOError(data)
    print(data.columns)
    print(data)
    return RET_OK, data

futu = FutuClient()
futu.client.set_handler(CurKline())
futu.client.subscribe(['HK.HSIcurrent'], [SubType.K_1M])
