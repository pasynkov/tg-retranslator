
EventFactory = require "../classes/event_factory"
TelegramApi = require "../integrations/telegram/api"

async = require "async"

class Retranslator

  constructor: (@processExitCallback)->

    @logger = vakoo.logger.retranslator

    @tgApi = new TelegramApi

    @initialize (err)=>
      if err
        @logger.error "Initialize crushed with err: `#{err}`"
      else
        @logger.info "Initialized successfully"

  initialize: (callback)=>

    async.waterfall(
      [
        @tgApi.initialize
        async.apply @tgApi.initializeEvents, @onMessage
      ]
      callback
    )


  onMessage: (chat, callback)=>

    if chat.authorIsMe()

      @logger.info "Ignore bot's message"
      callback()

    else

      try
        @emitEvent chat, callback
      catch e
        #todo kill this
        console.error e.stack
        callback()

  emitEvent: (chat, callback)=>
    event = EventFactory::getInstance chat
    event.process callback

module.exports = Retranslator