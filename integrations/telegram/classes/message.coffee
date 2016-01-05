_ = require "underscore"
async = require "async"

class Message

  constructor: (@attrs)->

    @logger = vakoo.logger.telegram

  getType: =>

    @type ?= _.chain(@attrs).keys().without("message_id", "from", "chat", "date").first().value()

    return @type

  getAuthorId: =>
    @attrs.from.id

  getText: =>

    @attrs.text or @getCaption()

  getMediaField: =>

    if @getType() in ["photo", "document"]
      @attrs[@getType()]
    else
      throw new Error ("Message with type `#{@getType()}` hasnt media")

  getProcessingFileId: =>

    media = @getMediaField()

    if _.isArray(media)
      media = _.max media, (f)-> f.file_size

    media.file_id


  getCaption: =>

    @attrs.caption

  hasTag: (tag)=>

    (new RegExp("##{tag}")).test @getText()


module.exports = Message