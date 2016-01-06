
Event = require "./event"

START = "start"
STOP = "stop"
LINK = "link"
UNLINK = "unlink"
MUTE = "mute"
SETTINGS = "settings"
STATUS = "status"
LOCALE = "locale"
HELP = "help"

COMMAND_LIST = [
  START
  STOP
  LINK
  UNLINK
  MUTE
  SETTINGS
  LOCALE
  HELP
]

async = require "async"
_ = require "underscore"

StorageDecorator = require "../decorators/storage"

class Command extends Event

  constructor: ->
    super

    @commandName = "help"

    @args = []

    @storage = new StorageDecorator


  process: (callback)=>

    async.waterfall(
      [
        @parseAttributes

        @chat.clearAnticipant

        (taskCallback)=>

          @logger.info "Start processing command `#{@commandName}` with args `[#{@args.join(", ")}]`"

          switch @commandName
            when START then @startCommand taskCallback
            when STOP then @stopCommand taskCallback
            when LINK then @linkCommand taskCallback
            when UNLINK then @unlinkCommand taskCallback
            when MUTE then @muteCommand taskCallback
            when SETTINGS then @settingsCommand taskCallback
            when STATUS then @statusCommand taskCallback
            when HELP then @helpCommand taskCallback
            when LOCALE then @localeCommand taskCallback
            else @errorCommand taskCallback
      ]
      callback
    )



  parseAttributes: (callback)=>
    @commandName = @getCommandName()
    @args = @getArguments()

    callback()

  getArguments: =>

    messageArgs = @message.attrs.text.split(" ")

    if (anticipant = @chat.getAnticipant())

      messageArgs = _.flatten([
        anticipant.split(":")
        messageArgs
      ])

    [commandString, args ...] = messageArgs

    args

  isCommand: (chat = @chat)->

    _.identity @getCommandName(chat)

  getCommandName: (chat = @chat)=>

    message = chat.getCurrentMessage()

    if (anticipant = chat.getAnticipant())
      commandName = anticipant.split(":").shift()
    else
      _.find COMMAND_LIST, (c)=>
        (new RegExp "/#{c}", "i").test message.attrs.text.split(" ")[0]

  localeCommand: (callback)=>

    locale = _.last @args

    if locale in ["RU", "EN"]

      async.waterfall(
        [
          async.apply @chat.setLocale, locale
          @updateLocalizer
          async.apply async.asyncify(@getLocaleMessage), "LOCALE_SETTED"
          @sendMessage
        ]
        callback
      )

    else

      async.waterfall(
        [
          async.apply async.asyncify(@getLocaleMessage), "CHOOSE_LOCALE"

          (message, taskCallback)=>

            @chat.createKeyboard(true, true).addRow ["EN", "RU"]

            @sendMessage message, taskCallback

          async.apply @chat.setAnticipant, "locale"
        ]
      )

  settingsCommand: (callback)=>

    [section] = @args

    if section

      sectionAlias = _.find [
        "SETTINGS_PRIVACY"
        "SETTINGS_TAG"
        "SETTINGS_LANG"
      ], (phrase)=>
        @getLocaleMessage(phrase) is section

      if sectionAlias
        section = _.last sectionAlias.split("_")

      switch section.toLowerCase()
        when "privacy" then @sendPrivacyMenu callback
        when "tag" then @sendTagForm callback
        when "lang" then @localeCommand callback
        else @sendErrorMessage "UNKNOWN_SECTION"

    else

      @sendSettingsMenu callback

  sendTagForm: (callback)=>

    [section, tag] = @args

    if tag

      async.waterfall(
        [
          async.apply @chat.setTag, tag
          async.apply async.asyncify(@getLocaleMessage), "TAG_SETTED", tag
          @sendMessage
        ]
        callback
      )

    else

      async.waterfall(
        [
          async.apply async.asyncify(@getLocaleMessage), "TYPE_TAG"
          (message, taskCallback)=>

            options = {
              reply_markup: {
                force_reply: true
              }
            }

            taskCallback null, message, options

          @sendMessage

          async.apply @chat.setAnticipant, "settings:tag"
        ]
        callback
      )

  sendPrivacyMenu: (callback)=>

    [section, mode] = @args

    if mode

      async.waterfall(
        [
          async.apply @chat.setPrivacyMode, mode
          async.apply async.asyncify(@getLocaleMessage), "PRIVACY_MODE_SETTED_#{mode}", @chat.settings.tag
          (message, taskCallback)=>

            console.log "send", message

            if @chat.settings.privacy < 10 or @chat.settings.tag
              @sendMessage message, taskCallback
            else
              @sendTagForm taskCallback

        ]
        callback
      )

    else

      async.waterfall(
        [
          async.apply async.asyncify(@getLocaleMessage), "CHOOSE_PRIVACY_MENU"
          (text, taskCallback)=>
            options = {
              reply_to_message_id: @message.attrs.message_id
              reply_markup:
                reply_to_message_id: @message.attrs.message_id
                one_time_keyboard: true
                keyboard: _.chain(@chat.getPrivacyKeyboard()).map(
                  (row)=>
                    _.map row, (message)=>
                      @getLocaleMessage message
                ).value()
                selective: true
            }

            taskCallback null, text, options

          @sendMessage
          async.apply @chat.setAnticipant, "settings:privacy"
        ]
        callback
      )

  sendSettingsMenu: (callback)=>

    async.waterfall(
      [
        async.apply async.asyncify(@getLocaleMessage), "CHOOSE_SETTINGS_SECTION"
        (text, taskCallback)=>

          options = {
            reply_to_message_id: @message.attrs.message_id
            reply_markup:
              reply_to_message_id: @message.attrs.message_id
              one_time_keyboard: true
              keyboard: [
                [@getLocaleMessage("SETTINGS_PRIVACY")]
                [@getLocaleMessage("SETTINGS_TAG")]
                [@getLocaleMessage("SETTINGS_LANG")]
              ]
              selective: true
          }

          taskCallback null, text, options

        @sendMessage
        async.apply @chat.setAnticipant, "settings"
      ]
      callback
    )

  muteCommand: (callback)=>

    if @chat.isMute()

      @startCommand callback

    else

      @stopCommand callback

  unlinkCommand: (callback)=>

    async.waterfall(
      [
        @chat.unlink
        async.apply async.asyncify(@getLocaleMessage), "UNLINKED"
        @sendMessage
      ]
      callback
    )

  stopCommand: (callback)=>

    async.waterfall(
      [
        @chat.mute
        async.apply async.asyncify(@getLocaleMessage), "MUTE"
        @sendMessage
      ]
      callback
    )

  startCommand: (callback)=>

    async.waterfall(
      [
        @chat.unMute
        async.apply async.asyncify(@getLocaleMessage), "UNMUTE"
        @sendMessage
      ]
      callback
    )

  statusCommand: (callback)=>

    callback()

  helpCommand: (callback)=>

    [section] = @args

    if section

      section = @args.join(" ")

      section = _.find [
          "HELP_ABOUT"
          "HELP_SETTINGS"
      ], (phrase)=>

        @getLocaleMessage(phrase) is section

      unless section
        return @sendErrorMessage("UNKNOWN_COMMAND")

      text = @getLocaleMessage "HELP_SECTION_#{section.toUpperCase()}"

      @sendMessage text, callback

    else

      text = @getLocaleMessage "CHOOSE_HELP_SECTION"

      options = {
        reply_to_message_id: @message.attrs.message_id
        reply_markup:
          reply_to_message_id: @message.attrs.message_id
          one_time_keyboard: true
          keyboard: [
            [@getLocaleMessage("HELP_ABOUT")]
            [@getLocaleMessage("HELP_SETTINGS")]
          ]
          selective: true
      }

      @chat.setAnticipant "help", (err)=>

        if err
          return callback err

        @sendMessage text, options, callback

#      text = """
#        Select section:
#        [About](/help About)
#        /help Options
#      """
#
#      options = {
#
#        parse_mode: "Markdown"
#        disable_web_page_preview: true
#
#        reply_markup: {
#          reply_to_message_id: @message.attrs.message_id
##          force_reply: true
#          one_time_keyboard: true
#          keyboard: [
#            ["[HELP](/help About)", "/help About2"]
#            ["/help About3", "/help About4"]
#          ]
#          selective: true
#          force_reply: true
##          force_reply_keyboard: true
#        }
##        force_reply: true
##        reply_to_message_id: @message.attrs.message_id
#      }


  errorCommand: (callback)=>

    @logger.info "error command"

    callback()

  linkCommand: (callback)=>

    [pin] = @args

    if pin
      if @validatePin(pin)

        async.waterfall(
          [
            async.apply @chat.linkTwitterByPin, pin
            async.apply async.asyncify(@getLocaleMessage), "TW_SUCCESS_LINKED"
            @sendMessage
          ]
          callback
        )

      else
        @sendErrorMessage "PIN_NOT_VALID", callback
    else
      @sendTwitterAuthMessage callback

  validatePin: (pin)=>

    pin.length is 7 and not _.isNaN(+pin)

  sendTwitterAuthMessage: (callback)=>

    async.waterfall(
      [
        @chat.getTwitterAuthUrl

        async.apply async.asyncify(@getLocaleMessage), "GO_TO_TW_AUTH_URL"

        (message, taskCallback)=>

          @sendMessage message, {
            parse_mode: "Markdown"
            disable_web_page_preview: true
            reply_markup: {
              force_reply: true
            }
          }, taskCallback

        async.apply @chat.setAnticipant, "link"

      ]
      callback
    )





module.exports = Command
