{EventEmitter}  = require 'events'
debug           = require('debug')('meshblu-connector-particle-io:index')
_                       = require 'lodash'
channelJson             = require './channelJson'
schemas                 = require './legacySchemas.json'
request                 = require 'request'
OctobluRequestFormatter = require 'octoblu-request-formatter'
format                  = new OctobluRequestFormatter(channelJson)


class ParticleIo extends EventEmitter
  constructor: ->
    debug 'ParticleIo constructed'

  isOnline: (callback) =>
    callback null, running: true

  close: (callback) =>
    debug 'on close'
    callback()

  onMessage: (message) =>
    return unless message?
    { topic, devices, fromUuid } = message
    return if '*' in devices
    return if fromUuid == @uuid
    debug 'onMessage', { topic }
    return if !message.payload.endpoint?
    requestParams = format.processMessage message.payload, @auth, @defaultUrlParams

    debug 'formatted request', requestParams

    if @auth.access_token?
      requestParams.headers.Authorization = "bearer " + @auth.access_token
      debug 'Sending Request'
      request requestParams, (error, response, body) =>
        return @sendError error if error?
        body = JSON.parse(body)
        @emit 'message', devices: ["*"], payload: body
        debug 'Body: ', body

  onConfig: (config) =>
    return unless config?
    debug 'on config', @uuid
    @options = config.options

    @defaultUrlParams = {}
    @auth = {
      access_token: @options.access_token
    }

  start: (device) =>
    { @uuid } = device
    debug 'started', @uuid
    schemas = _.extend schemas, format.buildSchema()
    @emit 'update', schemas

  sendError: (ErrorMessage) =>
    @emit 'message', devices: ["*"], topic: 'error', payload: ErrorMessage


module.exports = ParticleIo
