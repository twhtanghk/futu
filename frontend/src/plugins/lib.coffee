volatility = require 'volatility'

# extract sublist of input array for every n consecutive elements
# e.g. subList [1..100], 2 = [[1, 2], [2, 3], ..., [99, 100]]
subList = (arr, n) ->
  if n > arr.length
    throw new Error 'invalid subarray size'
  i = 0
  for j in [n..arr.length]
    arr.slice i++, j

# return volatility for every n elements
# e.g. vol [{close: 2}, {close: 5}, ...], 3 = [1.2, 2.1, ...]
vol = (arr, n) ->
  close = arr.map ({close}) -> close
  subList close, n
    .map (i) ->
      volatility i

# update arr with volatility with short, medium, and long period
# e.g. volSML [{close: 2}, {close: 5} ...] =
#   [{close: 2, volatility: {s: 1.2, m: 2.6, l: 1.8}}, ...]
volSML = (arr, s, m, l) ->
  ret =
    s: vol arr, s
    m: vol arr, m
    l: vol arr, l
  for v, i in arr by -1
    v.volatility =
      s: ret.s[i - s]
      m: ret.m[i - m]
      l: ret.l[i - l]
  arr

export {subList, vol, volSML}
