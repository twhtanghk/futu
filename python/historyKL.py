#!/usr/bin/env python3
# historyKL.py HK.00700

from sys import argv
from futuClient import FutuClient

client = FutuClient()
try:
  print(client.historyKL({'code': argv[1]}).to_string())
except Exception as err:
  print("error:", err)
