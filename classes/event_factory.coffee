
Command = require "./command"
Event = require "./event"

TEXT_MESSAGE_TYPE = "text"
DOCUMENT_MESSAGE_TYPE = "document"
PHOTO_MESSAGE_TYPE = "photo"
enableClasses = [
  TEXT_MESSAGE_TYPE
  DOCUMENT_MESSAGE_TYPE
  PHOTO_MESSAGE_TYPE
]

class EventFactory

  constructor: ->

  getInstance: (chat)->

    Instance = @getInstanceForType chat
    new Instance chat

  getInstanceForType: (chat)->

    message = chat.getCurrentMessage()

    if chat.getAnticipant()
      Command
    else if message.getType() is TEXT_MESSAGE_TYPE and Command::isCommand chat
      Command
    else if @typeHasClass message.getType()
      require "./#{message.getType()}_event"
    else Event

  typeHasClass: (type)->
    type in enableClasses



module.exports = EventFactory