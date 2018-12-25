class KubeApi
  request = require 'request'

  constructor: (contextConfig) ->
    caFile = contextConfig['ca']
    if caFile and caFile != ""
      fs = require('fs')
      path = require('path')
      @ca = fs.readFileSync(caFile)
    @urlPrefix = contextConfig['server']
    @token = contextConfig['token']

  get: ({path, roles}, callback) ->
    requestOptions =
      url : @urlPrefix + path

    requestOptions['auth'] =
      bearer: @token

    if @ca
      requestOptions.agentOptions =
        ca: @ca

    request.get requestOptions, (err, response, data) ->
      return callback(err) if err
      if response.statusCode == 404
        return callback null, null
      if response.statusCode != 200
        return callback new Error("Error executing request: #{response.statusCode} #{data}")
      if data.startsWith "{"
        callback null, JSON.parse(data)
      else
        callback null, data

module.exports = KubeApi
