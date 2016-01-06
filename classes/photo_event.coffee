Event = require "./event"

async = require "async"

class PhotoEvent extends Event

  constructor: ->
    super

  process: (callback)=>

    @logger.info "Start processing photo"

    @chat.downloadAndTwitMediaIfAllow callback


module.exports = PhotoEvent