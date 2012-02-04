# License goes here

class Sender
  
  constructor: (@conf, @cli, @server) ->

  send: ->
    console.log @conf, @server.pending


module.exports = Sender