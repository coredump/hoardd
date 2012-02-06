Fs = require 'fs'

module.exports = (server) ->
  run = () ->
    metricPrefix = "#{server.fqdn}.interfaces"
    server.cli.debug "Running the interfaces plugin"
    nameArray = [
      'rxBytes', 'rxPackets', 'rxErrors', 'rxDrops', 
      'rxFifo', 'rxFrame', 'rxCompressed', 'rxMulticast',
      'txBytes', 'txPackets', 'txErrors', 'txDrops', 
      'txFifo', 'txColls', 'txCarrier', 'txCompressed'
    ]

    # Reads from proc
    procfile = '/proc/net/dev'
    content = Fs.readFileSync(procfile, 'ascii').trim()
    for line in content.split('\n')[2...]
      continue if line.match /lo:/ 
      values = line.trim().split /\s+/
      interface = values[0].replace /:$/, ''
      statObj = {}
      statObj[key] = values[i + 1] for key, i in nameArray
      server.push_metric "#{metricPrefix}.#{interface}.#{key}", value for key, value of statObj 
