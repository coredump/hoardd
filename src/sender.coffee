Net = require 'net'
Graphite = require 'graphite'

class Sender
  
  constructor: (@conf, @cli, @server) ->

  send: ->
    return unless @server.pending.length > 0
    url  = "plaintext://#{@conf.carbonHost}:#{@conf.carbonPort}"
    conn = Graphite.createClient url

    @cli.debug "Sending metrics to #{url}"
    while metric = @server.pending.shift()
      toSend = {}
      toSend[metric[0]] = metric[1]
      conn.write toSend, metric[2], (err) =>
        if err
          @cli.error "Could not send metrics, will send when the connection is back up: #{err}"
      @cli.debug "#{metric}"
    
    conn.end()
    @server.samplesRun = 0

module.exports = Sender
