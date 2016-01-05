TwitterApi = require "../../../integrations/twitter/api"

Message = require "./message"

ChatSettings = require "../../../classes/chat_settings"
Event = require "../../../classes/event"

fs = require "fs"

async = require "async"
_ = require "underscore"


#privacy modes

PHOTO_AND_TEXT_PRIVACY_MODE = 0
TEXT_ONLY_PRIVACY_MODE = 1
PHOTO_ONLY_PRIVACY_MODE = 2

#privacy modes with tag

PHOTO_AND_TEXT_TAG_PRIVACY_MODE = 10
TEXT_ONLY_TAG_PRIVACY_MODE = 11
PHOTO_ONLY_TAG_PRIVACY_MODE = 12

class ReplyMarkup

  getObject: => @params

class Keyboard extends ReplyMarkup

  constructor: (oneTime = false, selective = false, resize = false)->

    @params = {
      resize_keyboard: resize
      one_time_keyboard: oneTime
      selective: selective
      keyboard: []
    }

  addRow: (buttons)=>

    @params.keyboard.push buttons

    return @


class ForceReply extends ReplyMarkup

  constructor: (selective = false)->

    @params = {
      force_reply: true
      selective: selective
    }

class HideKeyboard extends ReplyMarkup

  constructor: (selective = false)->

    @params = {
      selective
      hide_keyboard: true
    }


class Chat

  constructor: (attrs, @bot)->

    @retranslatorConfig = vakoo.configurator.config.retranslator

    @attrs = attrs.chat

    @currentMessage = new Message attrs

    @logger = vakoo.logger.telegram

    @settings = new ChatSettings @

    @twitter = new TwitterApi

    @replyMarkup = null


  createHideKeyboard: (selective)=>

    @replyMarkup = new HideKeyboard selective

    @replyMarkup

  createForceReply: (selective)=>

    @replyMarkup = new ForceReply selective

    @replyMarkup

  createKeyboard: (oneTime, selective, resize)=>

    @replyMarkup = new Keyboard oneTime, selective, resize

    @replyMarkup

  sendMessage: ([text, options] ..., callback)=>

    options ?= {}

    unless options.reply_markup
      unless @replyMarkup
        @createHideKeyboard()

      options.reply_markup = @replyMarkup.getObject()

    options.parse_mode = "Markdown"

    console.log "sendMessage", text, options

    @bot.sendMessage(@getId(), text, options)
    .then(
      =>

        @logger.info "Send message `#{text}` with opts `#{JSON.stringify options}` successfully"

        callback()
      callback
    )

  getCurrentMessage: =>
    @currentMessage

  getTwitterAuthUrl: (callback)=>

    @twitter.getAuthCredentials (err, {requestToken, requestTokenSecret, url})=>
      if err
        return callback err

      @settings.setTwitterSettings {requestToken, requestTokenSecret}, (err)->
        callback err, url


  getId: =>
    @attrs.id

  getCurrentMessageType: =>
    @currentMessage.getType()

  getBotId: =>

    @bot.id

  initialize: (callback)=>
    @settings.initialize (err)=>

      @twitter.setSettings @settings.twitter

      callback err, @

  getLocale: =>
    @settings.locale

  setLocale: (locale, callback)=>
    @settings.locale = locale

    @settings.saveSettings callback

  authorIsMe: =>
    @currentMessage.getAuthorId() is @getBotId()

  setAnticipant: (commandName, callback)=>

    @settings.anticipant = commandName

    @settings.saveSettings callback

  getAnticipant: =>

    @settings.anticipant

  linkTwitterByPin: (pin, callback)=>

    @logger.info "Start link twitter for chat `#{@getId()}`"

    @twitter.getAccessToken pin, (err, {accessToken, accessTokenSecret})=>

      if err
        return callback err

      @settings.setTwitterSettings {accessToken, accessTokenSecret, linked: true}, (err)->
        callback err

  clearAnticipant: (callback)=>

    @settings.anticipant = false

    @settings.saveSettings callback

  isLinked: =>

    @settings.twitter.linked is true

  unlink: (callback)=>

    @settings.twitter = {}

    @settings.saveSettings callback

  isMute: =>

    @settings.mute is true

  changeMuteTo: (value, callback)=>

    @settings.mute = value

    @settings.saveSettings callback

  mute: (callback)=>

    @changeMuteTo yes, callback

  unMute: (callback)=>

    @changeMuteTo no, callback

  canTwitText: =>

    _.chain(
      "#{@settings.privacy}".split("")
    ).map((i)-> +i).last().value() in [0,1]

  canTwitPhoto: =>

    _.chain(
      "#{@settings.privacy}".split("")
    ).map((i)-> +i).last().value() in [0,2]


  messageHasTagIfRequired: =>

    if @settings.privacy < 10
      return true

    return @currentMessage.hasTag @settings.tag


  twitCurrentMessageIfAllow: (callback)=>

    reasonForSkip = _.find(
      [
        if @isLinked() then false else "Chat `#{@getId()}` isnt linked, skipping twit"
        if @isMute() then "Chat `#{@getId()}` is muted, skipping twit" else false
        if @canTwitText() then false else "Chat `#{@getId()}` mute for text, skipping twit"
        if @messageHasTagIfRequired() then false else "Chat `#{@getId()}` mute for text wihout tag, skipping twit"
      ]
      _.identity
    )

    if reasonForSkip
      @logger.warn reasonForSkip
      callback()
    else
      @logger.info "Start twit text"

      @twitText @currentMessage.getText(), callback


  twitText: (text, callback)=>

    @twitter.sendText text, callback


  twitMedia: (mediaId, callback)=>

    @logger.info "Start twit media `#{mediaId}`"

    @twitter.twitMedia mediaId, @currentMessage.getCaption(), callback

  downloadFile: (fileId, callback)=>

    @logger.info "Start download file"

    @bot.downloadFile(fileId, @retranslatorConfig.tmpFileDir)
    .then(
      (filePath)=>
        callback null, filePath
      callback
    )

  getFileContentAndRemoveThem: (filePath, callback)=>

    @logger.info "Start read and remove file"

    fs.readFile filePath, (err, content)->

      if err
        return callback err

      fs.unlink filePath, (err)->
        callback err, content

  uploadFileContentToTwitter: (fileContent, callback)=>

    @logger.info "Start upload media to twitter"

    @twitter.uploadMedia fileContent, callback

  setTag: (tag, callback)=>

    @settings.tag = tag

    @settings.saveSettings callback

  downloadAndTwitMediaIfAllow: (callback)=>


    reasonForSkip = _.find(
      [
        if @isLinked() then false else "Chat `#{@getId()}` isnt linked, skipping twit"
        if @isMute() then "Chat `#{@getId()}` is muted, skipping twit" else false
        if @canTwitPhoto() then false else "Chat `#{@getId()}` mute for text, skipping twit"
        if @messageHasTagIfRequired() then false else "Chat `#{@getId()}` mute for text wihout tag, skipping twit"
      ]
      _.identity
    )

    if reasonForSkip
      @logger.warn reasonForSkip
      callback()
    else
      @downloadAndTwitMedia @message.getProcessingFileId(), callback

  downloadAndTwitMedia: (fileId, callback)=>

    async.waterfall(
      [
        @downloadFile
        @getFileContentAndRemoveThem
        @uploadFileContentToTwitter
        @twitMedia
      ]
      callback
    )

  getPrivacyModes: =>

    [
      {
        #textOnly
        code: TEXT_ONLY_PRIVACY_MODE
        message: "TEXT_ONLY_PRIVACY_MODE"
      }
      {
        #photoOnly
        code: PHOTO_ONLY_PRIVACY_MODE
        message: "PHOTO_ONLY_PRIVACY_MODE"
      }
      {
        #photo and text
        code: PHOTO_AND_TEXT_PRIVACY_MODE
        message: "PHOTO_AND_TEXT_PRIVACY_MODE"
      }
      {
        #only photo with tag
        code: PHOTO_ONLY_TAG_PRIVACY_MODE
        message: "PHOTO_ONLY_TAG_PRIVACY_MODE"
      }
      {
        #only text with tag
        code: TEXT_ONLY_TAG_PRIVACY_MODE
        message: "TEXT_ONLY_TAG_PRIVACY_MODE"
      }
      {
        #photo and text with tag
        code: PHOTO_AND_TEXT_TAG_PRIVACY_MODE
        message: "PHOTO_AND_TEXT_TAG_PRIVACY_MODE"
      }
    ]


  getPrivacyKeyboard: =>

    [withTag, withoutTag] = _.partition @getPrivacyModes(), (m)->
      /tag/i.test m.message

    [
      _.chain(withoutTag).sortBy((m)-> m.code).map((m)->m.message).value()
      _.chain(withTag).sortBy((m)-> m.code).map((m)->m.message).value()
    ]

  setPrivacyMode: (modeMessage, callback)=>

    modeAlias = Event::getMessageAlias modeMessage, @getLocale()

    mode = _.find @getPrivacyModes(), (m)-> m.message is modeAlias

    @settings.privacy = mode?.code

    @logger.info "Set privacy settings `#{mode.code}`"

    @settings.saveSettings callback





module.exports = Chat