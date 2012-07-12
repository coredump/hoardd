EventEmitter = require('events').EventEmitter
Sender       = require './sender'
Path         = require 'path'
Util         = require 'util'
Fs           = require 'fs'

class HoardD extends EventEmitter
  
  constructor: (@conf, @cli) ->
    @sPath = @conf.scriptPath
    @fqdn = @conf.fqdn.split('.').join('_')
    @namespace = @conf.namespace or 'hoard'
    @samplesRun = 0
    @util = Util

    # Containers
    @scripts  = []
    @pending  = []
    super

  load_scripts: ->
    for file in Fs.readdirSync @sPath
      ext = Path.extname file
      continue unless ext in [ '.coffee', '.js' ]
      toLoad = Path.join(@sPath, Path.basename file)
      try
        @cli.info "Loading script #{toLoad}"
        @scripts.push(require(toLoad) @)
      catch error
        @cli.fatal "Failed to load #{toLoad}: #{error}"
        process.exit()

  now: ->
    date  = new Date()
    now   = Math.round date.getTime()/1000

  push_metric: (prefix, value) ->
    try
      metric = "hoard.#{prefix} #{value} #{@now()}"
      @pending.push metric
      @cli.debug metric
    catch error
      @cli.fatal "Error adding metric: #{error}"

  run_scripts: ->
    for script in @scripts
      try
        script()
      catch error
        @cli.fatal "Error while running #{script.name}: #{error}"
    @samplesRun += 1
    @cli.debug "sample runs: #{@samplesRun}"
    @send_metrics() if @samplesRun >= @conf.sendEach
    if @samplesRun >= @conf.maxFailedSends
      @cli.fatal "Too many failed sends (#{@conf.maxFailedSends}): bailing out" 

  send_metrics: ->
    sender = new Sender @conf, @cli, @
    sender.send()
  
module.exports = HoardD