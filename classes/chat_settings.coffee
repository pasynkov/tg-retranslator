
StorageDecorator = require "../decorators/storage"

DEFAULT_PRIVACY_MODE = 0

class ChatSettings

  constructor: (@chat)->

    @storage = new StorageDecorator

    @privacy = DEFAULT_PRIVACY_MODE

    @twitter = {}

    @anticipant = false

    @mute = true

    @locale = "EN"

    @tag = ""

  initialize: (callback)=>

    @storage.getChatSettings @chat.getId(), (err, settings)=>

      for key, val of settings

        @[key] = val

      callback err

  saveSettings: (callback)=>

    @storage.setChatSettings @chat.getId(), @getSettingsObject(), (err)->
      callback err

  getSettingsObject: =>

    {
      privacy: @privacy
      twitter: @twitter
      anticipant: @anticipant
      mute: @mute
      locale: @locale
      tag: @tag
    }

  setTwitterSettings: (settings, callback)=>

    @twitter = settings

    @saveSettings callback



module.exports = ChatSettings