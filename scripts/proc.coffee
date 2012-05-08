Exec  = require('child_process').exec

module.exports = (server) ->
  run = () ->
    metricPrefix = "#{server.fqdn}.cpu"
    server.cli.debug "Running the vmstat script"
    nameArray = [
      'user', 'nice', 'system', 'idle', 'iowait',
      'irq', 'softirq', 'steal', 'guest', 'guest_nice'
    ]
    size = 0
    first = new Object
    second = new Object
    tosend = new Object
    # Depends on /proc/stat
    Exec 'cat /proc/stat | grep "^cpu[0-9]"', { timeout: server.conf.sampleInterval * 1000},  (err, stdout, stderr) ->
      lines = stdout.trim().split('\n')
      size = lines.length
      (
        vals = line.trim().split /\s+/
        name = vals.shift()
        first[name] = new Object
        i = 0
        (
          first[name][nameArray[i]] = vals.shift()
          i++
        ) while vals.length > 0
      ) for line in lines
      setTimeout ( ->
        Exec 'cat /proc/stat | grep "^cpu[0-9]"', { timeout: server.conf.sampleInterval * 1000},  (err, stdout, stderr) ->
          lines = stdout.trim().split('\n')
          (
            vals = line.trim().split /\s+/
            name = vals.shift()
            second[name] = new Object
            i = 0
            (
              second[name][nameArray[i]] = vals.shift()
              i++
            ) while vals.length > 0
          ) for line in lines
          (
            (
              unless first["cpu#{i}"][name] is undefined
                if tosend["cpu#{i}"] is undefined
                  tosend["cpu#{i}"] = new Object
                  tosend["cpu#{i}"].total = 0
                tosend["cpu#{i}"][name] = second["cpu#{i}"][name]-first["cpu#{i}"][name]
                tosend["cpu#{i}"]["total"] += tosend["cpu#{i}"][name]
            ) for name in nameArray
          ) for i in [0..size-1]
          (
            (
              unless tosend["cpu#{i}"][name] is undefined
                server.push_metric "#{metricPrefix}.#{i}.#{name}", (1000*tosend["cpu#{i}"][name]/tosend["cpu#{i}"]["total"])/10
            ) for name in nameArray
          ) for i in [0..size-1]
        ), 1000
