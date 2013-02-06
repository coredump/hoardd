pg = require 'pg'

# Metrics to get as s from the client_info object
metrics =
    'server.numbackends'             : 'select sum(numbackends) as s from pg_stat_database'   # backends currently connected
    'server.committed_transactions'  : 'select sum(xact_commit) as s from pg_stat_database'   # transactions that have been committed
    'server.rolledback_transactions' : 'select sum(xact_rollback) as s from pg_stat_database' # transactions that have been rolled back
    'server.blks_read'               : 'select sum(blks_read) as s from pg_stat_database'     # disk blocks read
    'server.blks_hit'                : 'select sum(blks_read) as s from pg_stat_database'     # times disk blocks were found in cache
    'server.tup_returned'            : 'select sum(tup_returned) as s from pg_stat_database'  # rows returned by queries
    'server.tup_fetched'             : 'select sum(tup_fetched) as s from pg_stat_database'   # rows fetched by queries
    'server.tup_inserted'            : 'select sum(tup_inserted) as s from pg_stat_database'  # rows inserted by queries
    'server.tup_updated'             : 'select sum(tup_updated) as s from pg_stat_database'   # rows updated by queries
    'server.tup_deleted'             : 'select sum(tup_deleted) as s from pg_stat_database'   # rows deleted by queries
    'server.conflicts'               : 'select sum(conflicts) as s from pg_stat_database'     # queries canceled due to conflicts
    #'server.temp_files'              : 'select sum(temp_files) as s from pg_stat_database'    # temporary files created by queries
    #'server.temp_bytes'              : 'select sum(temp_bytes) as s from pg_stat_database'    # Amount of data written to temporary files
    #'server.deadlocks'               : 'select sum(deadlocks) as s from pg_stat_database'     # deadlocks detected

module.exports = (server) ->
  run = () ->
    metricPrefix = "#{server.fqdn}.postgresql"
    server.cli.debug "Running the postgresql plugin"

    # This script needs configuration
    confPath     = Path.join server.sPath, 'postgresql.json'
    configFile   = Fs.readFileSync confPath, 'utf-8'
    conf         = JSON.parse configFile

    conn = pg.connect conf,  (error, client) ->
      return server.cli.error "Error when connect to PostgreSQL: #{error}" if error?

      for own metricKey, metricQuery of metrics
        do (metricKey, metricQuery) ->
          client.query metricQuery, (error, result) ->
            return server.cli.error "Error when querying to PostgreSQL: #{error}" if error?
            server.push_metric("#{metricPrefix}.#{metricKey}", result.rows[0].s)
