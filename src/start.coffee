Server = require './server'
Path   = require 'path'
Cli    = require('cli').enable('status', 'version')
Fs     = require 'fs'

# Command Line Setup
module.exports = entry_point = () ->
  Cli.enable 'version'
  Cli.setUsage 'node start.js -c <config json>'
  Cli.setApp 'HoardDaemon', '0.1.0'
  Cli.parse
    'config': ['c', 'Configuration file path', 'path', './config.json']

  Cli.main (args, options) ->
    if Path.existsSync options.config
      try
        conf = JSON.parse(Fs.readFileSync(options.config, 'utf-8'))
      catch error
        Cli.debug "Error parsing config file: #{error}"
    else
      Cli.fatal "Can't find a config file"

    hoard = new Server conf, Cli
    hoard.load_scripts()

    hoard.on 'run', hoard.run_scripts

    setInterval(->
      hoard.emit 'run'
    ,conf.sampleInterval * 1000)

    Cli.info "HoardD started. Samples each #{conf.sampleInterval} seconds. Sending to graphite each #{conf.sendEach} samplings"
