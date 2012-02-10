Mysql = require 'mysql'
Fs    = require 'fs'
Path = require 'path'

# Metrics to get from the statuses
metrics = []

module.exports = (server) ->
  run = () ->
    server.cli.debug "Running the mysql plugin"
    metricPrefix = "#{server.fqdn}.mysql"
    data         = {}
    # This script needs configuration
    confPath     = Path.join server.sPath, 'mysql.json'
    configFile   = Fs.readFileSync confPath, 'utf-8'
    conf         = JSON.parse configFile
    
    conn = Mysql.createClient conf
    conn.query 'SHOW GLOBAL STATUS', (err, res, fields) ->
      if err
        server.cli "Error on STATUS query: #{err}"

      for row in res
        data[row.Variable_name] = row.Value

      conn.query 'SHOW SLAVE STATUS', (err, res, fields) ->
        if err
          server.cli "Error on SLAVE STATUS query: #{err}"

        data[key] = value for key, value of res[0]

        console.log "Data: #{server.util.inspect data}"