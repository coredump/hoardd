Net = require 'net'

class Sender
  
  constructor: (@conf, @cli, @server) ->

  send: ->
    return unless @server.pending.length > 0
    lines = @server.pending.join('\n') + '\n'
    conn = Net.connect @conf.carbonPort, @conf.carbonHost
    conn.addListener 'error', (error) =>
      @cli.debug "Connection error: #{error}"
    conn.on 'connect', () =>
      @cli.debug "Connected to #{@conf.carbonHost}:#{@conf.carbonPort}"
      try
        @cli.debug "Sending lines: #{lines}"
        conn.write lines
        @server.pending = []
        @server.samplesRun = 0
      catch error
        @cli.error "Failed to send data: #{error}"
        throw new Error "Failed to send data: #{error}"
      finally
        @cli.debug "Disconnected"
        conn.end()

module.exports = Sender
