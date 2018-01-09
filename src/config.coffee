# Configuration:
#   HUBOT_K8S_CONTEXTS - map for kubernetes contexts (like kubectl), example: {"default":{"server":"https://kubernetes.example.org:6443","ca":"/kube-ca.crt","token":"kube-token","dashboardPrefix":"https://kubernetes.example.org"}}
#   HUBOT_K8S_DEFAULT_CONTEXT - default context to use
#   HUBOT_K8S_DEFAULT_NAMESPACE - default namespace to use

moment = require "moment"

class Config
  @contexts: JSON.parse process.env.HUBOT_K8S_CONTEXTS
  @defaultContext = process.env.HUBOT_K8S_DEFAULT_CONTEXT
  @defaultNamespace = process.env.HUBOT_K8S_DEFAULT_NAMESPACE

  @resourceAliases =
    "dep": "deployments"
    "svc": "services"

  @getContext = (res) ->
    user = res.message.user.id
    key = "#{user}.context"
    return robot.brain.get(key) or @defaultContext

  @setContext = (res, context) ->
    user = res.message.user.id
    key = "#{user}.context"
    return robot.brain.set(key, context or @defaultContext)

  @getNamespace = (res) ->
    user = res.message.user.id
    key = "#{user}.namespace"
    return robot.brain.get(key) or @defaultNamespace

  @setNamespace = (res, namespace) ->
    user = res.message.user.id
    key = "#{user}.namespace"
    return robot.brain.set(key, namespace or @defaultNamespace)

  @responses =
    'services': (response, dashboardPrefix) ->
      reply = ''
      for service in response.items
        {metadata: {name, namespace}, spec: {clusterIP, ports}} = service
        internalPorts = []
        nodePorts = []
        for p in ports
          {protocol, port, nodePort} = p
          internalPorts.push "#{port}/#{protocol}"
          nodePorts.push "#{nodePort}/#{protocol}"
        reply += ">*<#{dashboardPrefix}/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/service/#{namespace}/#{name}?namespace=#{namespace}|#{name}>*\n"
        reply += ">ports `#{internalPorts.join(" ")}` and node ports `#{nodePorts.join(" ")}` with cluster ip: `#{clusterIP}`\n\n"
      return reply
    'pods': (response, dashboardPrefix) ->
      reply = ''
      for pod in response.items
        {metadata: {name, namespace}, status: {phase, startTime, containerStatuses}} = pod
        reply += ">*<#{dashboardPrefix}/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/pod/#{namespace}/#{name}?namespace=#{namespace}|#{name}>*\n"
        reply += ">status `#{phase}` since `#{moment(startTime).fromNow()}`\n"
        for cs in containerStatuses
          {name, restartCount, image} = cs
          reply += ">container `#{name}` with restart count `#{restartCount}` and image `#{image}`\n"
        reply += "\n"
      return reply

module.exports = Config
