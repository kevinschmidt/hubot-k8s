# Hubot Kubernetes Bot
Let's you connect to multiple kubernetes environments and interact with them.

Thanks to https://github.com/canthefason/hubot-kubernetes for the inspiration.

### Configuration:
- `HUBOT_K8S_CONTEXTS` `{"prod":{"server":"https://kubernetes.cluster.io","ca":"./ca.crt","dashboardPrefix":"https://kubernetes.cluster.io","token":"<kubernetes token>"}}`
- `HUBOT_K8S_DEFAULT_CONTEXT` - Default context (from above config)
- `HUBOT_K8S_DEFAULT_NAMESPACE` - Default namespace in Kubernetes

### Commands:

All commands operate in the currently selected namespace and context. All commands with label selectors accept it in the form `label=value`.

#### Display Current Kubernetes Context
> k8s context

#### Switching Kubernetes Context
> k8s context `<context>`

#### Display Current Kubernetes Namespace
> k8s namespace|ns

#### Switching Kubernetes Namespace
> k8s namespace|ns `<namespace>`

#### List Deployments
> k8s deployments|deploy [`<labelSelector>`]

#### List Services
> k8s services|svc [`<labelSelector>`]

#### List Cron Jobs
> k8s cronjobs [`<labelSelector>`]

#### List Jobs
> k8s jobs [`<labelSelector>`]

#### Get logs from a pod
> k8s logs|log `<pod name>`
