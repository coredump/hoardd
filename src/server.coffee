# License goes here

EventEmitter  = require('events').EventEmitter
Sender        = require './sender'
Path          = require 'path'
Fs            = require 'fs'

class HoardD extends EventEmitter
  
  constructor: (@conf, @cli) ->
    sPath = @conf.scriptPath
    @fqdn = @conf.fqdn.split('.').join('_')

    # Containers
    @scripts  = []
    @pending  = []

    for file in Fs.readdirSync sPath
      ext = Path.extname file
      continue unless ext == '.coffee'
      toLoad = Path.join(sPath, Path.basename(file, ext))
      try
        @scripts.push(require(toLoad) @)
      catch error
        @cli.fatal "Failed to load #{toLoad}: #{error}"
        process.exit()
    super

  now: ->
    date  = new Date()
    now   = Math.round date.getTime()/1000

  push_metric: (prefix, value) ->
    try
      @pending.push "#{prefix} #{value} #{@now()}"
    catch error
      @cli.fatal "Error adding metric: #{error}"

  run_scripts: ->
    for script in @scripts
      try
        script()
      catch error
        @cli.fatal "Error while running #{script.name}: #{error}"

  send_metrics: ->
    sender = new Sender @conf, @cli, @
    sender.send()

module.exports = HoardD