import moment from 'moment'
Futu = require('../index').default

do ->
  try
    broker = await new Futu()
    {g, destory} = await broker.dataKL
      market: 'hk'
      code: '00700'
      start: moment().subtract day: 1
      freq: 1
    for await i from g()
      console.log i
  catch err
    console.error err
