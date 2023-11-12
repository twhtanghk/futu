import pandas as pd
import numpy as np
from mpl_finance import candlestick_ohlc
import matplotlib.dates as mpl_dates
import matplotlib.pyplot as plt

def isSupport(df, i):
  return df['low'][i] < df['low'][i - 1] and df['low'][i] < df['low'][i + 1] and df['low'][i + 1] < df['low'][i + 2] and df['low'][i - 1] < df['low'][i - 2]

def isResistance(df, i):
  return df['high'][i] > df['high'][i - 1] and df['high'][i] > df['high'][i + 1] and df['high'][i + 1] > df['high'][i + 2] and df['high'][i - 1] > df['high'][i - 2]

# check if price is too close to existing level
def meanDiff(mean, price, levels):
  return np.sum([abs(price - y) < mean for level_type, i, y in levels]) == 0

def levels(df):
  levels = []
  mean = np.mean(df['high'] - df['low'])
  for i in range(2, df.shape[0] - 2):
    if isSupport(df, i):
      if meanDiff(mean, df['low'][i], levels):
        levels.append(('support', i, df['low'][i].round(2)))
    elif isResistance(df, i):
      if meanDiff(mean, df['high'][i], levels):
        levels.append(('resistance', i, df['high'][i].round(2)))
  return levels

def plot(df):
  code = df['code'][0]
  df = df.filter(items=['time_key', 'open', 'high', 'low', 'close'])
  df = df.rename(columns={'time_key': 'date'})
  df['date'] = pd.to_datetime(df['date'])
  df['date'] = df['date'].apply(mpl_dates.date2num)
  fig, ax = plt.subplots()
  candlestick_ohlc(ax, df.values, width=0.6, colorup='green', colordown='red', alpha=0.8)
  date_format = mpl_dates.DateFormatter('%d %b %Y')
  ax.xaxis.set_major_formatter(date_format)
  fig.autofmt_xdate()
  fig.tight_layout()

  for level_type, i, price in levels(df):
    plt.hlines(price,
               xmin = df['date'][i],
               xmax = max(df['date']),
               colors = 'blue')
    plt.text(df['date'][i], price, (str(level_type) + ': ' + str(price) + ' '), ha='right', va='center', fontweight='bold', fontsize='x-small')
    plt.title('Support and Resistance levels for ' + code, fontsize=24, fontweight='bold')
    fig.show()
  plt.savefig('a.png')

import unittest
from futuClient import FutuClient

class TestUtil(unittest.TestCase):
  def test_basic(self):
    try:
      client = FutuClient()
      data = client.historyKL({'code': 'HK.00700'})
      print(levels(data))
      plot(data)
    except Exception as err:
      self.fail(err)
