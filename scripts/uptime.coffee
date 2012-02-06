os = require 'os'

module.exports = (server) ->
  run = () ->
    metricPrefix = "#{server.fqdn}.uptime"
    server.cli.debug "Running uptime script"

    # Node os object makes this easy
    uptime = os.uptime()
    server.push_metric metricPrefix, uptime