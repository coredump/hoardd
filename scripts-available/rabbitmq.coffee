Rest  = require('restler')
Fs    = require 'fs'
Path  = require 'path'

module.exports = (server) ->
  run = () ->
    # This script needs configuration
    confPath     = Path.join server.sPath, 'rabbitmq.json'
    configFile   = Fs.readFileSync confPath, 'utf-8'
    conf         = JSON.parse configFile
    stats = ['ack', 'deliver', 'deliver_get', 'deliver_no_ack', 'publish', 'redeliver', 'return_unroutable']
    send_stat = (stat, data) ->
      try
        server.push_metric "rabbitmq.#{stat}.count", data.message_stats[stat]
        server.push_metric "rabbitmq.#{stat}.rate", data.message_stats["#{stat}_details"].rate
      catch error
       server.cli.debug error
      
    Rest.get("#{conf.host}:#{conf.port}/api/overview",
      {username: conf.username, password: conf.password}).on 'complete', (data) ->
      rmq_data = eval data
      send_stat stat, rmq_data for stat in stats
