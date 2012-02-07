Redis = require 'redis'

# Metrics to get from the client_info object
metrics = ['uptime_in_seconds', 'uptime_in_days', 'connected_clients',
           'connected_slaves', 'blocked_clients', 'used_memory', 'changes_since_last_save',
           'total_connections_received', 'total_commands_processed'
          ]

module.exports = (server) ->
  run = () ->
    metricPrefix = "#{server.fqdn}.redis"
    server.cli.debug "Running the redis plugin"

    conn = Redis.createClient()
    conn.on 'ready', ->
      server.push_metric("#{metricPrefix}.#{key}",
                         value) for key, value of conn.server_info when key in metrics
      conn.end()

    conn.on 'error', (error) ->
      server.cli.error "Error when connect to Redis: #{error}"