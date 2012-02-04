# License goes here

Server  = require './src/server'
Path    = require 'path'
Cli     = require('cli').enable('status', 'version')
Fs      = require 'fs'

# Command Line Setup
Cli.enable 'version'
Cli.setUsage 'start.coffee -c <config json>'
Cli.setApp 'HoardDaemon', '0.1.0'
Cli.parse 
  'config': ['c', 'Configuration file path', 'path', './config.json']

Cli.main (args, options) ->
  if Path.existsSync options.config
    conf = JSON.parse(Fs.readFileSync(options.config, 'utf-8'))
  else
    Cli.fatal "Can't find a config file"

  hoard = new Server conf, Cli

  hoard.on 'run', hoard.run_scripts
  hoard.on 'send', hoard.send_metrics

  setInterval(->
    hoard.emit 'run'
  ,conf.sampleInterval * 1000)

  setInterval(->
    hoard.emit 'send'
  ,conf.sendInterval * 1000)