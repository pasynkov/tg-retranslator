
Event = require "./event"

_ = require "underscore"

class TextEvent extends Event

  constructor: ->
    super

  process: (callback)=>

    @trasmit callback

  trasmit: (callback)=>

    @logger.info "Trasmitting ..."

    @chat.twitCurrentMessageIfAllow callback





module.exports = TextEvent