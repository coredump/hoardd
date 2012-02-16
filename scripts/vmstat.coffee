Exec  = require('child_process').exec

module.exports = (server) ->
  run = () ->
    metricPrefix = "#{server.fqdn}.vmstat"
    server.cli.debug "Running the vmstat script"
    nameArray = [
      'runningProcs', 'blockedProcs',
      'swpdMem', 'freeMem', 'buffMem', 'cacheMem',
      'swapIn', 'swapOut',
      'blocksIn', 'blocksOut',
      'interrupts', 'contextSwitches',
      'userCPU', 'systemCPU', 'idleCPU', 'waitingCPU'
    ]

    # Depends on vmstat 
    # Timeouts on sampleInterval seconds, will cause problems with sampleIntervals too small
    Exec 'vmstat 1 2', { timeout: server.conf.sampleInterval * 1000},  (err, stdout, stderr) ->
      lastLine = stdout.trim().split('\n')
      statArray = lastLine[lastLine.length - 1].trim().split /\s+/
      statObj = {}
      statObj[key] = statArray[i] for key, i in nameArray 
      server.push_metric "#{metricPrefix}.#{key}", value for key, value of statObj