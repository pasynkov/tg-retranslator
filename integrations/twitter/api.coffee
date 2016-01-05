
Client = require "node-twitter-api"

async = require "async"

class TwitterApi

  constructor: ->

    @logger = vakoo.logger.twitter

    @config = vakoo.configurator.config.twitter

    @client = new Client {
      consumerKey: @config.apiKey
      consumerSecret: @config.secretKey
    }

  getAuthCredentials: (callback)=>

    if @requestToken and @requestTokenSecret
      return callback null, {
        requestToken: @requestToken
        requestTokenSecret: @requestTokenSecret
        url: @client.getAuthUrl @requestToken
      }

    @client.getRequestToken (err, requestToken, requestTokenSecret, results)=>
      if err
        return callback err

      callback null, {
        requestToken
        requestTokenSecret
        url:  @client.getAuthUrl requestToken
      }

  setSettings: ({@requestToken, @requestTokenSecret, @accessToken, @accessTokenSecret})=>


  getAccessToken: (pin, callback)=>

    @client.getAccessToken @requestToken, @requestTokenSecret, pin, (err, accessToken, accessTokenSecret, results)=>

      if err
        return callback err, {}

      callback null, {
        accessToken
        accessTokenSecret
      }

  sendText: (text, callback)=>

    text += " by @tg_speaker"

    @client.statuses "update", {status: text}, @accessToken, @accessTokenSecret, (err, data, res)=>

      if err
        return callback err

      @logger.info "Text twitting complete successfully"

      callback()

  uploadMedia: (media, callback)=>

    @client.uploadMedia {media}, @accessToken, @accessTokenSecret, (err, result)->

      callback err, result?.media_id_string

  twitMedia: (mediaId, status, callback)=>

    data = {media_ids: mediaId}

    if status
      data.status = status + " by @tg_speaker"

    @client.statuses "update", data, @accessToken, @accessTokenSecret, (err, data, res)=>

      if err

        console.log err, data

        return callback err

      @logger.info "Media twitting complete successfully"

      callback()







module.exports = TwitterApi