'use strict'
###
WorkQueueBroker Example -- provider03

For each string in the two expectedItems lists, this app sends it
into either 'work-queue-1' or 'work-queue-2' for consumption by worker03.
When done with that, it quits.

Usage:
  cd demo/lib
  export NODE_PATH='../../..'
  node provider01.js clear
  node provider01.js
  node provider01.js 10
  ...
  node provider01.js stop

Use this app in conjunction with worker03.js. See the worker03 source code
for more details.
###
myWorkQueue1 = null
myWorkQueue2 = null
myBroker = null
expectedItemsQ1 = [
    'item one',
    'item two',
    'item three',
]
itemCntQ1 = 0
expectedItemsQ2 = [
    'item foo',
    'item bar',
    'item baz',
]
itemCntQ2 = 0

clear = process.argv[2] is 'clear'
stop = process.argv[2] is 'stop'
timesToRepeat = parseInt(process.argv[2]) or 1

WorkQueueBroker = require('node-redis-queue').WorkQueueBroker

myBroker = new WorkQueueBroker()
myBroker.connect () ->
  console.log 'work queue broker ready'
  initEventHandlers()
  createWorkQueues()
  if stop
    sendStop()
    shutDown()
  else if clear
    clearWorkQueues ->
      shutDown()
  else
    sendData()
    shutDown()

initEventHandlers = ->
  myBroker.on 'error', (error) ->
    console.log '>>>' + error
    shutDown()
  myBroker.on 'end', ->
    console.log '>>>End Redis connection'
    shutDown()

createWorkQueues = ->
  myWorkQueue1 = myBroker.createQueue 'work-queue-1'
  myWorkQueue2 = myBroker.createQueue 'work-queue-2'
  return

clearWorkQueues = (done) ->
  queuesToClear = 2
  myWorkQueue1.clear () ->
    console.log 'Cleared "work-queue-1"'
    done() unless --queuesToClear
  myWorkQueue2.clear () ->
    console.log 'Cleared "work-queue-2"'
    done() unless --queuesToClear

sendData = ->
  while timesToRepeat--
    for item in expectedItemsQ1
      console.log 'publishing "' + item + '" to queue "work-queue-1"'
      myWorkQueue1.send item

    for item in expectedItemsQ2
      console.log 'publishing "' + item + '" to queue "work-queue-2"'
      myWorkQueue2.send item
  return

sendStop = ->
  console.log 'stopping worker03'
  myWorkQueue1.send '***stop***'
  myWorkQueue2.send '***stop***'

shutDown = ->
  myBroker.shutdownSoon()

