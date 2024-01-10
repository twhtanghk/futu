# futu
futu broker:
  methods: 
    subscribe, unsubscribe
    ohlc:
      history, stream, data (generator for ohlc data in history and stream)
    account:
      position
    order:
      history, stream, data
  event:
    candle, trdUpdate
algotrader:
  data:
    input opts:
      broker
    constant:
      freqDuration
    Broker::
      historyKL, streamKL, dataKL (generator for ohlc data in history and stream)
  strategy:
    methods:
      meanReversion, levelVol, priceVol
  analysis:
    methods:
      levels, isSupport, isResistance
