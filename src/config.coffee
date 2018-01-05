# Configuration:
#   HUBOT_K8S_CONTEXTS - map for kubernetes contexts (like kubectl), example: {"default":{"server":"https://kubernetes.example.org:6443","ca":"/kube-ca.crt","token":"kube-token"}}
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
    'services': (response) ->
      reply = ''
      for service in response.items
        {metadata: {creationTimestamp}, spec: {clusterIP, ports}} = service
        internalPorts = ""
        nodePorts = ""
        for p in ports
          {protocol, port, nodePort} = p
          internalPorts += "#{port}/#{protocol} "
          nodePorts += "#{nodePort}/#{protocol} "
        reply += ">*#{service.metadata.name}*:\n" +
        ">Internal Ports: #{internalPorts}\n>Node Ports: #{nodePorts}\n>Cluster ip: #{clusterIP}\n"
      return reply
    'pods': (response) ->
      reply = ''
      for pod in response.items
        {metadata: {name}, status: {phase, startTime, containerStatuses}} = pod
        reply += ">*#{name}*:\n>Status: #{phase}, since: #{moment(startTime).fromNow()} \n"
        for cs in containerStatuses
          {name, restartCount, image} = cs
          reply += ">Container Name: #{name}\n>Restarts: #{restartCount}\n>Image: #{image}\n"
      return reply

module.exports = Config
