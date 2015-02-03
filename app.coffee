os = require 'os'
fs = require 'fs'
_ = require 'underscore'
request = require 'request'
helpers = require 'helpers'
UdpGun = require 'udp-client'


settings =
    host: 'logserver'
    port: "5001"
    interval: helpers.minute
    extendPacket:
        type: 'btc',
        host: os.hostname()
        
if fs.existsSync('./settings.js') then _.extend settings, require('./settings').setting

gun = new UdpGun settings.port, settings.host

queryBlockChain = (callback) ->
    console.log 'query!'
    request 'https://blockchain.info/ticker', (error, response, body) -> 
        if error then return helpers.cbc callback, error
        if response.statusCode isnt 200 then return helpers.cbc callback, 'got response code ' + response.statusCode
        console.log 'got',body
        
        try
            helpers.cbc callback, null, JSON.parse(body)
        catch error
            console.log error
            return helpers.cbc callback, 'unable to parse the data received as json'


submitData = (packet) ->
    packet = _.extend packet, settings.extendPacket
    console.log 'sending', packet
    gun.send new Buffer JSON.stringify packet
    
queryLoop = ->
    queryBlockChain (err,data) ->
        if err then console.error err
        else submitData data
        setTimeout queryLoop, settings.interval

queryLoop()