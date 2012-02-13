HoardD, send ALL metrics to graphite!
=====================================

What is HoardD
---------------

HoardD is a [node.js](http://nodejs.org/)/[coffee-script](http://coffeescript.org/) tool to send metrics to [Graphite](http://graphite.wikidot.com/). The objective here is to send specifically server data like disk stats, network, cpu, that can later be used for graphs using Graphite default web application or [Graphiti](http://dev.paperlesspost.com/blog/2011/12/16/introducing-graphiti-an-alternate-frontend-for-graphite/).

Data is collected using a series of *scripts*  written in coffee-script (js too but at the moment it only reads the files ended with .coffee). Writing new metrics is easy as creating a new coffee script and pushing it to the server pending queue.

There are other projects that do the same: [collectd](http://collectd.org/) has some plugins to send data to graphite and [diamond-gmond](https://github.com/freemed/diamond-gmond) is a python daemon that does exactly the same as this one (I only got to know diamond after I was 90% done on the first version of HoardD).

Install, configure and run it
---------------------------------

Configuration is done using the a `json` file. The package includes a default config that you probably can use after changing the hostname for your graphite/carbon node. HoardD was meant to be used with runit and similar tools so no daemonizing is done and all the logging is written on stdout (use `--debug` if you want detailed info on what is happening.) By default scripts sample the data each 10 seconds, and then sends the data to graphite each 6 samples are collected, effectively making one connection each 60 seconds.

Also, HoardD was made to be used with chef (or any other configuration management system) so while I know that configuring the FQDN on the config JSON is annoying, it was meant to be automatically filled by a template. If you are managing lots of servers and configs by hand in 2012 you are doing it wrong.

The master branch will be updated only to working versions (i.e: I will *try* not to break it), so you can probably just do a clone/fetch/pull from it on new versions.

### Scripts and specific configuration

The MySQL script is an example of how to configure specific scripts. It contains a `mysql.json` file that is read by the script when it starts. Just make sure to:

* Keep the configs with the same name as the plugin (like, `mysql.coffee` and `mysql.json`)
* Put/link the configuration on the script path (together with the scripts)

For real, you can do whatever you want on your scripts, but it's better to make it easier for other people to configure/understand, so let's stick to a default.

Retentions, sample interval and counter metrics
------------------------------------------------

### Retentions and sample interval

Something mus be said about those things if you never used graphite. The first is the relation between the retentions configured on `storage-schemas.conf` and HoardD `sampleInterval` setting. On my tests results were more accurate if you make the retention time for the smaller retention the same as the sample interval. Results can be strange and even data can be lost in case of non-matching values. So, for the default sample interval of 10 seconds you need something like

```cfg
retentions = 10s:60m,1m:24h,15m:5y
```

### Counter metrics

Counter metrics are ever increasing counters, like the ones used on `/proc/net/interfaces`, if you want to get a per second graphic (like Kb/s in the interfaces speed case) you need to apply Graphite functions: `derivative` and `scale`.

`derivative` will make the graphs show the difference between 2 samples of data instead of an ever increasing counter, so if your counter increased from 1000 to 1100 between 2 samples the graph will show 100, not 1100. Now this is between 2 samples, and your samples are each 10 seconds so Graphite makes an average of it. If you need the graph on a per-second basis you must apply the `scale` function that will multiply that value by a ratio. If you need the graph in per seconds you then must multiply the value by 1/10 = 0.1. 

**TL;DR**: use `derivative` to make the graph show differences between two samples and `scale` to make it show per second. The scale is always 1/*data retention value* of the graph.

For example, for network speed:

```
scale(derivative(hoard.host.interfaces.eth0.txBytes),0.1)
```

Writing new scripts
--------------------

To add new scripts just drop the `.coffee` or `.js` file on `scriptPath` and restart HoardD (making it detect new scripts without restarting is on TODO).

Writing new scripts should be easy:

* Change the variables
* Write what you need to do on the `run` function
* Use `obj.push_metric <metric name> <value>`

`obj` is an Object that is passed as the argument for each script and gives you some tools

* `push_metric` to add metrics to the pending array to be sent to graphite
* `cli` has all the methods from the [cli](https://github.com/chriso/cli) module (use it for logging)
* `fqdn` the server FQDN configured on the JSON config file for you to use on metrics

Code speaks better than words in some case, this is the `load_average.coffee` script:

```coffeescript
Fs = require 'fs'
Path = require 'path'

module.exports = (server) ->
  run = () ->
    metricPrefix = "#{server.fqdn}.load_average"
    server.cli.debug "Running load average script"

    # Read from /proc
    procfile = '/proc/loadavg'
    if Path.existsSync procfile
      data = Fs.readFileSync(procfile, 'utf-8')
      [one, five, fifteen] = data.split(' ', 3)
      server.push_metric "#{metricPrefix}.short", one
      server.push_metric "#{metricPrefix}.medium", five
      server.push_metric "#{metricPrefix}.long", fifteen
```

And this is the `uptime.js` script:

```javascript
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
```

Take a look at the code of the other scripts and you will see that there's nothing genius going on there. 

If you write something cool, make sure to send me a patch, push-request, anything! The tool is as good as the scripts available for it really.

License and author
------------------

HoardD is licensed under the MIT License but please, send back your changes :). A copy of the license is included on the LICENSE file.

You can read announcements and news on http://coredump.io

