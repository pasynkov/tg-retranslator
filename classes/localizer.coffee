class Localizer

  messages = null

  constructor: (locale)->

    if locale.toLowerCase() not in ["ru", "en"]
      locale = "ru"

    messages = require "../locals/#{locale.toLowerCase()}/messages.json"

  getMessage: (key)->

    messages[key] or @getEmptyMessage(key)

  getEmptyMessage: (key)->
    "`#{key}`"
        

module.exports = Localizer