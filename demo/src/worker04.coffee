'use strict'
###
WorkQueueMgr Example -- worker04

This app consumes work requests that become available in the 'demo:urlq' queue,
as provided by provider04. For each one it receives, this app computes an
SHA1 value on the request URL (req.url) and outputs that and the request
URL value (req.url) to the result queue (req.q) specified in the work request.
provider04 consumes the data in the result queue.

However, if this app receives a '***stop***' message, it closes the connection
and quits immediately.

Usage:
   cd demo/lib
   export NODE_PATH='../../..'
   node worker04.js
 or
   node worker04.js 3
 to demonstrate arity feature.
 or
   node worker04.js 1 5
 to demonstrate the timeout feature.


Use this app in conjunction with provider04.js. See the provider04 source code
for more details.
###
WorkQueueMgr = require('node-redis-queue').WorkQueueMgr
request = require 'request'
SHA1 = require('../lib/helpers/tinySHA1.r4.js').SHA1
urlQueueName = 'demo:urlq'
urlQueue = null
arity = parseInt(process.argv[2]) or 1
timeout = parseInt(process.argv[3]) or 0
console.log 'arity=' + arity + ', timeout=' + timeout

mgr = new WorkQueueMgr()

onReady = ->
  console.log 'channel connected'
  initEventHandlers()
  createUrlQueue()
  consumeUrlQueue()
  console.log 'waiting for work...'

if arity is 1
  console.log 'connecting half-duplex'
  mgr.connect onReady
else
  console.log 'connecting full-duplex'
  mgr.connect2 onReady

initEventHandlers = ->
  mgr.on 'end', ->
    console.log 'worker04 detected Redis connection ended'
    shutDown()

  mgr.on 'error', (error) ->
    console.log 'worker04 stopping due to error'
    throw error
    shutDown()

  mgr.on 'timeout', (keys, cancel) ->
    console.log '>>>timeout, keys=', keys

createUrlQueue = ->
  urlQueue = mgr.createQueue urlQueueName
  return

consumeUrlQueue = ->
  urlQueue.consume (req, ack) ->
    if typeof req is 'object'
      console.log 'worker04 processing request ', req, ' (' + mgr.channel.outstanding + ')'
      request req.url, (error, response, body) ->
        if not error and response.statusCode is 200
          sha1 = SHA1 body
          console.log 'sending ' + req.url + ' SHA1 = ' + sha1, ' (' + mgr.channel.outstanding + ')'
          mgr.channel.push req.q, {url: req.url, sha1: sha1}
          ack()
        else
          console.log '>>>error: ', error
          mgr.channel.push req.q, {url: req.url, err: error}
          ack()
    else
      if typeof req is 'string' and req is '***stop***'
        console.log 'worker04 stopping'
        shutDown()
      console.log 'Unexpected message: ', req
      console.log 'Type of message = ' + typeof req
      shutDown()
  , arity, timeout

shutDown = ->
  mgr.end()
  process.exit()
