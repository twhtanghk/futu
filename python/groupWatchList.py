#!/usr/bin/env python

from sys import argv
from futu import *

client = OpenQuoteContext(host='futu', port=11111)
ret, data = client.get_user_security(argv[1])
if ret == RET_OK:
  print(data.to_string())
else:
  print("error:", data)
client.close()
