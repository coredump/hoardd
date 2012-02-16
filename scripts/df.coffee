Exec  = require('child_process').exec

module.exports = (server) ->
  run = () ->
    metricPrefix = "#{server.fqdn}.df"
    server.cli.debug "Running the df script"
    nameArray = [
      'used', 'available', 'percent', 'mount_point'
    ]

    # Depends on vmstat 
    # Timeouts on sampleInterval seconds, will cause problems with sampleIntervals too small
    Exec 'df -P', { timeout: server.conf.sampleInterval * 1000},  (err, stdout, stderr) ->
      lines = stdout.trim().split '\n'
      statObj = {}
      for line in lines
        if line.match /^\//
          statArray = line.replace(/%/, '').split(/\s+/)[2..]
          statArray[3] = 'root' if statArray[3] == '/'
          statObj[key] = statArray[i] for key, i in nameArray 

          server.push_metric("#{metricPrefix}.#{statObj.mount_point}.#{key}",
                             value) for key, value of statObj when key isnt 'mount_point' 
