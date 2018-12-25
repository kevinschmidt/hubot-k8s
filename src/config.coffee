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
    "deploy": "deployments"
    "po": "pods"
    "svc": "services"

  @resourceApiPrefix =
    "deployments": "/apis/extensions/v1beta1"
    "jobs": "/apis/batch/v1"
    "cronjobs": "/apis/batch/v1beta1"

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
    'cronjobs': (response, dashboardPrefix) ->
      reply = ''
      for cronjob in response.items
        {metadata: {name, namespace}, spec: {schedule, suspend}, status: {lastScheduleTime}} = cronjob
        reply += ">*<#{dashboardPrefix}/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/cronjob/#{namespace}/#{name}?namespace=#{namespace}|#{name}>* - "
        reply += "schedule `#{schedule}` and suspended `#{suspend}` last scheduled `#{moment(lastScheduleTime).fromNow()}`\n"
      return reply
    'deployments': (response, dashboardPrefix) ->
      reply = ''
      for deployment in response.items
        {metadata: {name, namespace}, status: {replicas, updatedReplicas, readyReplicas, availableReplicas}} = deployment
        reply += ">*<#{dashboardPrefix}/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/deployment/#{namespace}/#{name}?namespace=#{namespace}|#{name}>* - "
        reply += "desired `#{replicas}`, current `#{readyReplicas}`, updated `#{updatedReplicas}`, available `#{availableReplicas}`\n"
      return reply
    'jobs': (response, dashboardPrefix) ->
      reply = ''
      for job in response.items
        {metadata: {name, namespace}, status: {startTime, conditions}} = job
        statuses = []
        for condition in conditions
          statuses.push condition.type
        reply += ">*<#{dashboardPrefix}/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/job/#{namespace}/#{name}?namespace=#{namespace}|#{name}>* - "
        reply += "last started `#{moment(startTime).fromNow()}` with status `#{statuses.join(" ")}`\n"
      return reply
    'pods': (response, dashboardPrefix) ->
      reply = ''
      for pod in response.items
        {metadata: {name, namespace}, status: {phase, startTime, containerStatuses}} = pod
        podRestartCount = 0
        podReadyCount = 0
        podCount = 0
        for cs in containerStatuses
          {restartCount, ready, image} = cs
          podRestartCount = podRestartCount + restartCount
          podCount = podCount + 1
          if ready then podReadyCount = podReadyCount + 1
        reply += ">*<#{dashboardPrefix}/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/pod/#{namespace}/#{name}?namespace=#{namespace}|#{name}>* - "
        reply += "pods `#{podReadyCount}/#{podCount}` with status `#{phase}` and restart count `#{restartCount}` since `#{moment(startTime).fromNow()}`\n"
      return reply
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
        reply += ">*<#{dashboardPrefix}/api/v1/namespaces/kube-system/services/kubernetes-dashboard/proxy/#!/service/#{namespace}/#{name}?namespace=#{namespace}|#{name}>* - "
        reply += "ports `#{internalPorts.join(" ")}` and node ports `#{nodePorts.join(" ")}` with cluster ip `#{clusterIP}`\n"
      return reply

module.exports = Config
