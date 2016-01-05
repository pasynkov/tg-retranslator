
CHAT_SETTINGS = "-chat-settings-"

class StorageDecorator

  constructor: ->

    @instanceName = vakoo.instanceName

  getChatSettings: (chatId, callback)=>

    vakoo.redis.client.get "#{@instanceName}#{CHAT_SETTINGS}#{chatId}", (err, settings)->
      if err
        return callback err

      callback null, JSON.parse(settings) or {}

  setChatSettings: (chatId, settings, callback)=>
    vakoo.redis.client.set "#{@instanceName}#{CHAT_SETTINGS}#{chatId}", JSON.stringify(settings), (err)->
      callback err

module.exports = StorageDecorator