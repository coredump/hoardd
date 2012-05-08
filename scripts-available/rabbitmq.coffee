Rest  = require('restler')

module.exports = (server) ->
  run = () ->
    stats = ['ack', 'deliver', 'deliver_get', 'deliver_no_ack', 'publish', 'redeliver', 'return_unroutable']
    send_stat = (stat, data) ->
      try
        server.push_metric "rabbitmq.#{stat}.count", data.message_stats[stat]
        server.push_metric "rabbitmq.#{stat}.rate", data.message_stats["#{stat}_details"].rate
      catch error
       server.cli.debug error
      
    Rest.get("#{server.conf.rabbitmq.host}:#{server.conf.rabbitmq.port}/api/overview",
      {username: server.conf.rabbitmq.username, password: server.conf.rabbitmq.password}).on 'complete', (data) ->
      rmq_data = eval data
      send_stat stat, rmq_data for stat in stats
