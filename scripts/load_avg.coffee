Fs = require 'fs'
Path = require 'path'

module.exports = (server) ->
  run = () ->
    metricPrefix = "#{server.fqdn}.load_average"
    server.cli.debug "Running load average script"

    # Read from /proc
    procfile = '/proc/loadavg'
    if Path.existsSync procfile
      data = Fs.readFileSync(procfile, 'utf-8')
      [one, five, fifteen] = data.split(' ', 3)
      server.push_metric "#{metricPrefix}.short", one
      server.push_metric "#{metricPrefix}.medium", five
      server.push_metric "#{metricPrefix}.long", fifteen