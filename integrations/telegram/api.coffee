
TelegramBot = require "node-telegram-bot-api"
#TgBot = require "tg_bot"
_ = require "underscore"
async = require "async"


Chat = require "./classes/chat"


class TelegramApi

  constructor: ->

    @config = vakoo.configurator.config.telegram

    @logger = vakoo.logger.telegram

    @bot = new TelegramBot @config.token, polling: true

#    @tgBot = new TgBot @config.token

  initialize: (callback)=>

#    console.log "initialize"
#
#    @tgBot.connect =>
#      @tgBot.subscribe "*", (chat, message, e)->
#        console.log "event", chat, message, e
#
#    return

    @bot.getMe().then(
      ({id, first_name, username})=>

        @bot.id = id

        @logger.info "Bot `@#{username}` connected."

        callback()

      callback
    )

  initializeEvents: (handler, callback)=>

    @bot.on "message", (attributes)=>

      try

        chat = new Chat attributes, @bot

        @logger.info "Incoming `#{chat.getCurrentMessageType()}` message in chat `#{chat.getId()}`"

        async.waterfall(
          [
            chat.initialize
            handler
          ]
          (err)=>

            if err
              @logger.error "Handler for message `#{chat.getCurrentMessageType()}` of chat `#{chat.getId()}` crushed with err: `#{err}`"
              if err.stack
                @logger.error err.stack
              if _.isObject(err)
                @logger.error err
            else
              @logger.info "Handler for message `#{chat.getCurrentMessageType()}` of chat `#{chat.getId()}` successfully completed"
        )
      catch e

        console.error e.stack


    callback()

module.exports = TelegramApi