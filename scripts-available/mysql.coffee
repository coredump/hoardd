Mysql = require 'mysql'
Fs    = require 'fs'
Path  = require 'path'

# To configure this plugin use the mysql.json file and put it on the scripts/ directory
# Also remember that the user must be able to use SHOW SLAVE STATUS, it needs the 
# SUPER or REPLICATION CLIENT privileges, something like this:
# grant replication client on *.* to <user>;

# Metrics to get from the statuses
generalMetrics = 
  'rxBytes':                  'Bytes_received',
  'txBytes':                  'Bytes_sent',
  'keyRead_requests':         'Key_read_requests',
  'keyReads':                 'Key_reads',
  'keyWrite_requests':        'Key_write_requests',
  'keyWrites':                'Key_writes',
  'binlogCacheUse':           'Binlog_cache_use',
  'binlogCacheDiskUse':       'Binlog_cache_disk_use',
  'maxUsedConnections':       'Max_used_connections',
  'abortedClients':           'Aborted_clients',
  'abortedConnects':          'Aborted_connects',
  'threadsConnected':         'Threads_connected',
  'openFiles':                'Open_files',
  'openTables':               'Open_tables',
  'openedTables':             'Opened_tables',
  'slaveLag':                 'Seconds_Behind_Master',
  'fullJoins':                'Select_full_join',
  'fullRangeJoins':           'Select_full_range_join',
  'selectRange':              'Select_range',
  'selectRange_check':        'Select_range_check',
  'selectScan':               'Select_scan'

queryCache = 
  'queriesInCache':           'Qcache_queries_in_cache',
  'cacheHits':                'Qcache_hits',
  'inserts':                  'Qcache_inserts',
  'notCached':                'Qcache_not_cached',
  'lowMemPrunes':             'Qcache_lowmem_prunes'

counters =
  'questions':                'Questions'
  'select':                   'Com_select',
  'delete':                   'Com_delete',
  'insert':                   'Com_insert',
  'update':                   'Com_update',
  'replace':                  'Com_replace',
  'deleteMulti':              'Com_delete_multi',
  'insertSelect':             'Com_insert_select',
  'updateMulti':              'Com_update_multi',
  'replaceSelect':            'Com_replace_select'
  'handlerWrite':             'Handler_write',
  'handlerUpdate':            'Handler_update',
  'handlerDelete':            'Handler_delete',
  'handlerRead_first':        'Handler_read_first',
  'handlerRead_key':          'Handler_read_key',
  'handlerRead_next':         'Handler_read_next',
  'handlerRead_prev':         'Handler_read_prev',
  'handlerRead_rnd':          'Handler_read_rnd',
  'handlerRead_rnd_next':     'Handler_read_rnd_next'
  'handlerCommit':            'Handler_commit',
  'handlerRollback':          'Handler_rollback',
  'handlerSavepoint':         'Handler_savepoint',
  'handlerSavepointRollback': 'Handler_savepoint_rollback'

innodbMetrics = 
  'bufferTotal_pages':        'Innodb_buffer_pool_pages_total',
  'bufferFree_pages':         'Innodb_buffer_pool_pages_free',
  'bufferDirty_pages':        'Innodb_buffer_pool_pages_dirty',
  'bufferUsed_pages':         'Innodb_buffer_pool_pages_data',
  'pageSize':                 'Innodb_page_size',
  'pagesCreated':             'Innodb_pages_created',
  'pagesRead':                'Innodb_pages_read',
  'pagesWritten':             'Innodb_pages_written',
  'currentLockWaits':         'Innodb_row_lock_current_waits',
  'lockWaitTimes':            'Innodb_row_lock_waits',
  'rowLockTime':              'Innodb_row_lock_time',
  'fileReads':                'Innodb_data_reads',
  'fileWrites':               'Innodb_data_writes',
  'fileFsyncs':               'Innodb_data_fsyncs',
  'logWrites':                'Innodb_log_writes'
  'rowsUpdated':              'Innodb_rows_updated',
  'rowsRead':                 'Innodb_rows_read',
  'rowsDeleted':              'Innodb_rows_deleted',
  'rowsInserted':             'Innodb_rows_inserted',

metricGroups = 
  'general':        generalMetrics, 
  'query_cache':    queryCache, 
  'counters':       counters, 
  'innodb_metrics': innodbMetrics

module.exports = (server) ->
  run = () ->
    server.cli.debug "Running the mysql plugin"
    metricPrefix = "#{server.fqdn}.mysql"
    port = 3306
    data         = {}
    # This script needs configuration
    confPath     = Path.join server.sPath, 'mysql.json'
    configFile   = Fs.readFileSync confPath, 'utf-8'
    conf         = JSON.parse configFile
    
    {spawn} = require 'child_process'
    netstat = spawn 'netstat', ['-ntpl']
    grep = spawn 'grep', ['mysqld']

    netstat.stdout.on 'data', (data) ->
      grep.stdin.write(data)

    netstat.on 'close', (code) ->
      server.cli.error "netstat process exited with code " + code  if code isnt 0
      grep.stdin.end()

    grep.stdout.on 'data', (data) ->
      greppedLines = ("" + data).split( "\n" )
      i = 0
      while i < greppedLines.length
        unless greppedLines[i] is ""
          port = Math.round(/:([0-9][0-9][0-9][0-9])/.exec(greppedLines[i])[1])
          conn = Mysql.createClient({
          "host":      conf.localhost,
          "user":      conf.user,
          "password":  conf.password,
          "port": port
          })
          conn.query 'SHOW GLOBAL STATUS', (err, res, fields) ->
            if err
              server.cli.error "Error on STATUS query: #{err}"

            for row in res
              data[row.Variable_name] = row.Value

            conn.query 'SHOW SLAVE STATUS', (err, res, fields) ->
              if err
                server.cli.error "Error on SLAVE STATUS query: #{err}"

              data[key] = value for key, value of res[0]

              # Replication lag being null is bad, very bad, so negativate it here
              data['Seconds_Behind_Master'] = -1 if data['Seconds_Behind_Master'] == null  
              conn.end()

              for name, group of metricGroups
                server.push_metric("#{metricPrefix}.#{port}.#{name}.#{key}", 
                                    data[stat]) for key, stat of group 
        i++
