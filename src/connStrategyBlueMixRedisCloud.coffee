'use strict'
redis = require 'redis'

class ConnStrategyBlueMixRedisCloud
  getClient: (@config) ->
    if process.env.VCAP_SERVICES
      env = JSON.parse process.env.VCAP_SERVICES
      redisVersion = @config.redis_version or 'redis-2.6'
      credentials = env[redisVersion][0].credentials
      redisOptions = @config.redis_options
      @client = redis.createClient credentials.port, credentials.host, redisOptions
      @client.auth credentials.password if credentials.password
      return @client
    else
      console.log 'VCAP_SERVICES environment variable not set. Assume local redis server'
      redisPort = 6379
      redisHost = '127.0.0.1'
      redisOptions = @config.redis_options
      @client = redis.createClient redisPort, redisHost, redisOptions
      return @client

module.exports = new ConnStrategyBlueMixRedisCloud
