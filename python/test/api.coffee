request = require 'supertest'

describe 'futu', ->
  it 'quote', ->
    request 'http://localhost:8000'
      .get '/quote'
      .set 'X-HTTP-Method-Override', 'GET'
      .set 'Content-Type', 'application/json'
      .send symbol: [ 'HK.00388', 'HK.09988' ]
      .expect 200
      .then (res) ->
        console.log res.body
