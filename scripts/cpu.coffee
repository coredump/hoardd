Exec  = require('child_process').exec

module.exports = (server) ->
  run = () ->
    metricPrefix = "#{server.fqdn}.cpu"
    server.cli.debug "Running the cpu script"
    nameArray = [
      'user', 'nice', 'system', 'idle', 'iowait',
      'irq', 'softirq', 'steal', 'guest', 'guest_nice'
    ]
    # Depends on /proc/stat
    Exec 'cat /proc/stat | grep "^cpu[0-9]"', { timeout: server.conf.sampleInterval * 1000},  (err, stdout, stderr) ->
      lines = stdout.trim().split('\n')
      counter = 0
      (
        vals = line.trim().split /\s+/
        i = 0
        #remove the name
        vals.shift()
        (
          val = vals.shift()
          server.push_metric "#{metricPrefix}.#{counter}.#{nameArray[i]}", val
          i++
        ) while vals.length > 0
        counter++
      ) for line in lines
