#!/usr/bin/env python

from futu import *

client = OpenQuoteContext(host='futu', port=11111)
ret, data = client.get_user_security_group(group_type = UserSecurityGroupType.ALL)
if ret == RET_OK:
  print(data.to_string())
else:
  print("error:", data)
client.close()
