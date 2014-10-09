'use strict';

var RedisQueue, WorkQueue, WorkQueueBroker, WorkQueueBrokerError, events,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

events = require('events');

RedisQueue = require('./index');

WorkQueue = (function() {

  function WorkQueue(qmgr, queueName, options) {
    this.qmgr = qmgr;
    this.queueName = queueName;
    this.options = options;
    return this;
  }

  WorkQueue.prototype.subscribe = function(onJob) {
    this.onJob = onJob;
    return this;
  };

  WorkQueue.prototype.publish = function(payload) {
    this.qmgr.push(this.queueName, payload);
    return this;
  };

  WorkQueue.prototype.unsubscribe = function() {
    this.onJob = null;
    return this;
  };

  WorkQueue.prototype.clear = function(onClearComplete) {
    this.qmgr.clear(this.queueName, onClearComplete);
    return this;
  };

  return WorkQueue;

})();

WorkQueueBrokerError = (function(_super) {

  __extends(WorkQueueBrokerError, _super);

  function WorkQueueBrokerError() {
    return WorkQueueBrokerError.__super__.constructor.apply(this, arguments);
  }

  return WorkQueueBrokerError;

})(Error);

WorkQueueBroker = (function(_super) {

  __extends(WorkQueueBroker, _super);

  function WorkQueueBroker() {
    this.queues = {};
    this.qmgr = new RedisQueue();
    return this;
  }

  WorkQueueBroker.prototype.connect = function(onReady) {
    this.qmgr.connect(onReady);
    this.initEmitters_();
    return this;
  };

  WorkQueueBroker.prototype.attach = function(client, onReady) {
    this.client = client;
    this.qmgr.attach(this.client, onReady);
    return this.initEmitters_();
  };

  WorkQueueBroker.prototype.initEmitters_ = function() {
    var _this = this;
    this.qmgr.on('ready', function() {
      return _this.emit('ready');
    });
    this.qmgr.on('error', function(err) {
      return _this.emit('error', err);
    });
    this.qmgr.on('timeout', function() {
      return _this.emit('timeout');
    });
    this.qmgr.on('end', function() {
      return _this.emit('end');
    });
    return this.qmgr.on('message', function(queueName, payload) {
      if (_this.isValidQueueName(queueName) && _this.queues[queueName].onJob) {
        return _this.queues[queueName].onJob(payload);
      }
    });
  };

  WorkQueueBroker.prototype.createQueue = function(queueName, options) {
    return this.queues[queueName] = new WorkQueue(this.qmgr, queueName, options);
  };

  WorkQueueBroker.prototype.publish = function(queueName, payload) {
    if (this.isValidQueueName) {
      this.qmgr[queueName].publish(payload);
    }
    return this;
  };

  WorkQueueBroker.prototype.subscribe = function(queueName, onJob) {
    if (this.isValidQueueName(queueName)) {
      this.queues[queueName].onJob = onJob;
    }
    return this;
  };

  WorkQueueBroker.prototype.unsubscribe = function(queueName) {
    if (this.isValidQueueName(queueName)) {
      this.queues[queueName].onJob = null;
    }
    return this;
  };

  WorkQueueBroker.prototype.destroyQueue = function(queueName) {
    if (this.isValidQueueName(queueName)) {
      delete this.queues[queueName];
    }
    return this;
  };

  WorkQueueBroker.prototype.monitor = function(timeout) {
    var args;
    if (timeout == null) {
      timeout = 1;
    }
    args = Object.keys(this.queues);
    if (!(args.length > 0)) {
      throw new WorkQueueBrokerError('No queues exist');
    }
    args.unshift(timeout);
    this.qmgr.monitor.apply(this.qmgr, args);
    return this;
  };

  WorkQueueBroker.prototype.disconnect = function() {
    this.qmgr.disconnect();
    return true;
  };

  WorkQueueBroker.prototype.end = function() {
    this.qmgr.end();
    return true;
  };

  WorkQueueBroker.prototype.isValidQueueName = function(queueName) {
    if (!this.queues[queueName]) {
      throw new WorkQueueBrokerError('Unknown queue "' + queueName + '"');
    }
    return true;
  };

  return WorkQueueBroker;

})(events.EventEmitter);

module.exports = WorkQueueBroker;