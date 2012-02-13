var Os;

Os = require('os');

module.exports = function(server) {
  var run;

  run = function() {
    var metricPrefix, uptime;
    metricPrefix = server.fqdn + ".uptime";
    server.cli.debug("Running uptime script");

    // Node os object makes this easy
    uptime = Os.uptime();
    server.push_metric(metricPrefix, uptime);
  }
  return run;
}