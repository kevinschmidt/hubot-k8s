# Description:
# Lets you interact with kubernetes

Config = require "./config"
KubeApi = require "./kubeapi"

module.exports = (@robot) ->
  # get/set kubernetes context
  robot.respond /k8s\s*context\s*(.+)?/i, (res) ->
    context = res.match[1]
    if not context or context is ""
      return res.reply "Your current kubernetes context is: `#{Config.getContext(res)}`"
    Config.setContext res, context
    res.reply "Your current kubernetes context is changed to `#{context}`"

  # get/set kubernetes namespaces
  robot.respond /k8s\s*namespace\s*(.+)?/i, (res) ->
    namespace = res.match[1]
    if not namespace or namespace is ""
      return res.reply "Your current kubernetes namespace is: `#{Config.getNamespace(res)}`"
    Config.setNamespace res, namespace
    res.reply "Your current kubernetes namespace is changed to `#{namespace}`"

  robot.respond /k8s\s*(deployments|dep|pods|services|svc)\s*(.+)?/i, (res) ->
    context = Config.getContext(res)
    contextConfig = Config.contexts[context]
    namespace = Config.getNamespace(res)
    resource = res.match[1]
    if alias = Config.resourceAliases[resource] then resource = alias

    url = "namespaces/#{namespace}/#{resource}"
    if res.match[2] and res.match[2] != ""
      url += "?labelSelector=#{res.match[2].trim()}"

    kubeapi = new KubeApi(contextConfig)
    kubeapi.get {path: url}, (err, response) ->
      if err
        robot.logger.error err
        return res.send "Could not fetch *#{resource}* in namespace *#{namespace}* with context *#{context}*"
      return res.reply "Requested resource *#{resource}* with labelSelector *#{res.match[2]}* not found in namespace *#{namespace}* with context *#{context}*" unless response and response.items and response.items.length
      reply = "\n"
      responseFormat = Config.responses[resource] or ->
      reply = "Here is the list of *#{resource}* running in namespace *#{namespace}* with context *#{context}*\n"
      reply += responseFormat response
      res.reply reply

  robot.respond /k8s\s*(logs|log)\s*(.+)?/i, (res) ->
    context = Config.getContext(res)
    contextConfig = Config.contexts[context]
    namespace = Config.getNamespace(res)
    pod = res.match[2]

    url = "namespaces/#{namespace}/pods/#{pod}/log"
    kubeapi = new KubeApi(contextConfig)
    kubeapi.get {path: url}, (err, response) ->
      if err
        robot.logger.error err
        return res.send "Could not fetch logs for pod *#{pod}* in namespace *#{namespace}* with context *#{context}*"
      return res.reply "Requested *logs* not found for pod *#{pod}* in namespace *#{namespace}* with context *#{context}*" unless response
      reply = "\n"
      reply = "Here are latest logs from pod *#{pod}* in namespace *#{namespace}* with context *#{context}*\n"
      reply += "```\n"
      reply += response
      reply += "```"

      res.reply reply
