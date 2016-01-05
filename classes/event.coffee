
LOCALES =
  EN:
    GO_TO_TW_AUTH_URL: "Go to [Twitter Authorize Url]($1), take the PIN and type here."
    PIN_NOT_VALID: "PIN_NOT_VALID"
    TW_SUCCESS_LINKED: "TW_SUCCESS_LINKED"
    TYPE_NOT_SUPPORTED: "TYPE_NOT_SUPPORTED"
    CHOOSE_HELP_SECTION: "CHOOSE_HELP_SECTION"
    NOT_FOUND_MESSAGE: "__$1__"
    PHOTO_AND_TEXT_PRIVACY_MODE: "A"
    TEXT_ONLY_PRIVACY_MODE: "B"
    PHOTO_ONLY_PRIVACY_MODE: "C"
    PHOTO_AND_TEXT_TAG_PRIVACY_MODE: "X"
    PHOTO_ONLY_TAG_PRIVACY_MODE: "Y"
    TEXT_ONLY_TAG_PRIVACY_MODE: "Z"
  RU:
    GO_TO_TW_AUTH_URL: "Перейдите по ссылке [Twitter Authorize Url]($1), и введите полученный пинкод здесь."
    PIN_NOT_VALID: "PIN_NOT_VALID"
    TW_SUCCESS_LINKED: "TW_SUCCESS_LINKED"
    TYPE_NOT_SUPPORTED: "TYPE_NOT_SUPPORTED"
    CHOOSE_HELP_SECTION: "CHOOSE_HELP_SECTION"
    NOT_FOUND_MESSAGE: "__$1__"
    PHOTO_AND_TEXT_PRIVACY_MODE: "A"
    TEXT_ONLY_PRIVACY_MODE: "B"
    PHOTO_ONLY_PRIVACY_MODE: "C"
    PHOTO_AND_TEXT_TAG_PRIVACY_MODE: "X"
    PHOTO_ONLY_TAG_PRIVACY_MODE: "Y"
    TEXT_ONLY_TAG_PRIVACY_MODE: "Z"


_ = require "underscore"

Localizer = require "./localizer"

class Event

  constructor: (@chat)->

    @logger = vakoo.logger.retranslator

    @config = vakoo.configurator.config.retranslator

    @message = @chat.getCurrentMessage()

    @localizer = new Localizer @chat.getLocale()

  process: (callback)=>

    @logger.warn "Type `#{@chat.getCurrentMessageType()}` not supported"

    @sendErrorMessage "TYPE_NOT_SUPPORTED", callback


  sendMessage: ([text, options]..., callback)=>

    @chat.sendMessage text, options, callback

  getLocaleMessage: (message, params...)=>

    @localizer.getMessage(message).replace /\$([0-9])/, ->
      params.shift()

  sendErrorMessage: (message, callback)=>

    @sendMessage @getLocaleMessage(message), callback

  getMessageAlias: (message, locale)=>

    _.findKey LOCALES[locale], (value)->
      value is message





module.exports = Event