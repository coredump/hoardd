Fs    = require 'fs'

module.exports = (server) ->
  run = () ->
    metricPrefix = "#{server.fqdn}.memory"
    server.cli.debug 'Running the memory script'
    # From the proc
    memfile = '/proc/meminfo'

    content = Fs.readFileSync memfile, 'ascii'
    mem = {}
    for line in content.split('\n')
      mem.total       = parseInt(line.split(/\s+/)[1]) * 1024 if line.match /^MemTotal/
      mem.free        = parseInt(line.split(/\s+/)[1]) * 1024 if line.match /^MemFree/
      mem.buffers     = parseInt(line.split(/\s+/)[1]) * 1024 if line.match /^Buffers/
      mem.cached      = parseInt(line.split(/\s+/)[1]) * 1024 if line.match /^Cached/
      mem.swapTotal   = parseInt(line.split(/\s+/)[1]) * 1024 if line.match /^SwapTotal/
      mem.swapFree    = parseInt(line.split(/\s+/)[1]) * 1024 if line.match /^SwapFree/
    
    mem.swapUsed = mem.swapTotal - mem.swapFree
    mem.used = mem.total - mem.free
    mem.usedWOBuffersCaches = mem.used - (mem.buffers + mem.cached)
    mem.freeWOBuffersCaches = mem.free + (mem.buffers + mem.cached)
    server.push_metric "#{metricPrefix}.#{key}", value for key, value of mem