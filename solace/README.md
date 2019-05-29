# Solace PubSub+ Message Broker

The [Solace PubSub+](https://solace.com/products/) message broker offers publish/subscribe + queueing + request/reply + streaming + message replay all in single platform that’s easy to deploy, manage and scale across your cloud, on-premises and IoT environments.

## Introduction

This chart bootstraps a single-node or HA deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Local kubectl client installed and configured with access to a PKS cluster (pks get-credentials <cluster-name> executed)
- PV provisioner support in the underlying infrastructure with at least one Kubernetes StorageClass defined (the StorageClass name is assumed to be `standard` by default)
- Helm 2.9.x package manager client installed with [Role-based Access Control configured](https://github.com/helm/helm/blob/master/docs/rbac.md) and Tiller deployed

## Installing the Chart

If you are not using Harbor as a Helm repository which includes Solace then clone following GitHub project first:
```
git clone https://github.com/SolaceDev/solace-pks.git
cd solace-pks
```

To install the "solace" chart with the release name `my-release`:

```bash
# If not using a 
$ helm install --name my-release solace

# or with Solace in Harbor:
$ helm install --name my-release <helm-repo-name>/solace
```

The command deploys Solace PubSub+ on the Kubernetes cluster in a single-node minimum configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

By default a random password will be generated for the admin user. Note that random passwords are updated as part of an upgrade! If you'd like to set your own password change the username_admin_password
in the values.yaml.

You can retrieve your admin password by running the following command. Make sure to replace [YOUR_RELEASE_NAME]:

    printf $(printf '\%o' `kubectl get secret [YOUR_RELEASE_NAME]-mysql -o jsonpath="{.data.mysql-root-password[*]}"`)

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the MySQL chart and their default values.

| Parameter                                    | Description                                                                                  | Default                                              |
| -------------------------------------------- | -------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| `solace.redundancy`                          | `false` will create a single-node non-HA deployment; `true` will create an HA deployment with Primary, Backup and Monitor nodes | `false`           |
| `solace.size`                                | Connection scaling. Options: `dev` (requires minimum resources but no guaranteed performance), `prod100`, `prod1k` | `prod100`                      |
| `solace.username_admin_password`             | The password for the "admin" management user. Will autogenerate it if not provided for non-HA deployment. Must be provided for HA deployment! | Auto-generate |
| `imageTag`                                   | `mysql` image tag.                                                                           | `5.7.14`                                             |
| `busybox.image`                              | `busybox` image repository.                                                                  | `busybox`                                            |
| `busybox.tag`                                | `busybox` image tag.                                                                         | `1.29.3`                                             |
| `testFramework.image`                        | `test-framework` image repository.                                                           | `dduportal/bats`                                     |
| `testFramework.tag`                          | `test-framework` image tag.                                                                  | `0.4.0`                                              |
| `imagePullPolicy`                            | Image pull policy                                                                            | `IfNotPresent`                                       |
| `existingSecret`                             | Use Existing secret for Password details                                                     | `nil`                                                |
| `extraVolumes`                               | Additional volumes as a string to be passed to the `tpl` function                            |                                                      |
| `extraVolumeMounts`                          | Additional volumeMounts as a string to be passed to the `tpl` function                       |                                                      |
| `extraInitContainers`                        | Additional init containers as a string to be passed to the `tpl` function                    |                                                      |
| `mysqlRootPassword`                          | Password for the `root` user. Ignored if existing secret is provided                         | Random 10 characters                                 |
| `mysqlUser`                                  | Username of new user to create.                                                              | `nil`                                                |
| `mysqlPassword`                              | Password for the new user. Ignored if existing secret is provided                            | Random 10 characters                                 |
| `mysqlDatabase`                              | Name for new database to create.                                                             | `nil`                                                |
| `livenessProbe.initialDelaySeconds`          | Delay before liveness probe is initiated                                                     | 30                                                   |
| `livenessProbe.periodSeconds`                | How often to perform the probe                                                               | 10                                                   |
| `livenessProbe.timeoutSeconds`               | When the probe times out                                                                     | 5                                                    |
| `livenessProbe.successThreshold`             | Minimum consecutive successes for the probe to be considered successful after having failed. | 1                                                    |
| `livenessProbe.failureThreshold`             | Minimum consecutive failures for the probe to be considered failed after having succeeded.   | 3                                                    |
| `readinessProbe.initialDelaySeconds`         | Delay before readiness probe is initiated                                                    | 5                                                    |
| `readinessProbe.periodSeconds`               | How often to perform the probe                                                               | 10                                                   |
| `readinessProbe.timeoutSeconds`              | When the probe times out                                                                     | 1                                                    |
| `readinessProbe.successThreshold`            | Minimum consecutive successes for the probe to be considered successful after having failed. | 1                                                    |
| `readinessProbe.failureThreshold`            | Minimum consecutive failures for the probe to be considered failed after having succeeded.   | 3                                                    |
| `persistence.enabled`                        | Create a volume to store data                                                                | true                                                 |
| `persistence.size`                           | Size of persistent volume claim                                                              | 8Gi RW                                               |
| `persistence.storageClass`                   | Type of persistent volume claim                                                              | nil                                                  |
| `persistence.accessMode`                     | ReadWriteOnce or ReadOnly                                                                    | ReadWriteOnce                                        |
| `persistence.existingClaim`                  | Name of existing persistent volume                                                           | `nil`                                                |
| `persistence.subPath`                        | Subdirectory of the volume to mount                                                          | `nil`                                                |
| `persistence.annotations`                    | Persistent Volume annotations                                                                | {}                                                   |
| `nodeSelector`                               | Node labels for pod assignment                                                               | {}                                                   |
| `tolerations`                                | Pod taint tolerations for deployment                                                         | {}                                                   |
| `metrics.enabled`                            | Start a side-car prometheus exporter                                                         | `false`                                              |
| `metrics.image`                              | Exporter image                                                                               | `prom/mysqld-exporter`                               |
| `metrics.imageTag`                           | Exporter image                                                                               | `v0.10.0`                                            |
| `metrics.imagePullPolicy`                    | Exporter image pull policy                                                                   | `IfNotPresent`                                       |
| `metrics.resources`                          | Exporter resource requests/limit                                                             | `nil`                                                |
| `metrics.livenessProbe.initialDelaySeconds`  | Delay before metrics liveness probe is initiated                                             | 15                                                   |
| `metrics.livenessProbe.timeoutSeconds`       | When the probe times out                                                                     | 5                                                    |
| `metrics.readinessProbe.initialDelaySeconds` | Delay before metrics readiness probe is initiated                                            | 5                                                    |
| `metrics.readinessProbe.timeoutSeconds`      | When the probe times out                                                                     | 1                                                    |
| `metrics.flags`                              | Additional flags for the mysql exporter to use                                               | `[]`                                                 |
| `metrics.serviceMonitor.enabled`             | Set this to `true` to create ServiceMonitor for Prometheus operator                          | `false`                                              |
| `metrics.serviceMonitor.additionalLabels`    | Additional labels that can be used so ServiceMonitor will be discovered by Prometheus        | `{}`                                                 |
| `resources`                                  | CPU/Memory resource requests/limits                                                          | Memory: `256Mi`, CPU: `100m`                         |
| `configurationFiles`                         | List of mysql configuration files                                                            | `nil`                                                |
| `configurationFilesPath`                     | Path of mysql configuration files                                                            | `/etc/mysql/conf.d/`                                 |
| `securityContext.enabled`                    | Enable security context (mysql pod)                                                          | `false`                                              |
| `securityContext.fsGroup`                    | Group ID for the container (mysql pod)                                                       | 999                                                  |
| `securityContext.runAsUser`                  | User ID for the container (mysql pod)                                                        | 999                                                  |
| `service.annotations`                        | Kubernetes annotations for mysql                                                             | {}                                                   |
| `service.loadBalancerIP`                     | LoadBalancer service IP                                                                      | `""`                                                 |
| `ssl.enabled`                                | Setup and use SSL for MySQL connections                                                      | `false`                                              |
| `ssl.secret`                                 | Name of the secret containing the SSL certificates                                           | mysql-ssl-certs                                      |
| `ssl.certificates[0].name`                   | Name of the secret containing the SSL certificates                                           | `nil`                                                |
| `ssl.certificates[0].ca`                     | CA certificate                                                                               | `nil`                                                |
| `ssl.certificates[0].cert`                   | Server certificate (public key)                                                              | `nil`                                                |
| `ssl.certificates[0].key`                    | Server key (private key)                                                                     | `nil`                                                |
| `imagePullSecrets`                           | Name of Secret resource containing private registry credentials                              | `nil`                                                |
| `initializationFiles`                        | List of SQL files which are run after the container started                                  | `nil`                                                |
| `timezone`                                   | Container and mysqld timezone (TZ env)                                                       | `nil` (UTC depending on image)                       |
| `podAnnotations`                             | Map of annotations to add to the pods                                                        | `{}`                                                 |
| `podLabels`                                  | Map of labels to add to the pods                                                             | `{}`                                                 |
| `priorityClassName`                          | Set pod priorityClassName                                                                    | `{}`                                                 |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
$ helm install --name my-release \
  --set mysqlRootPassword=secretpassword,mysqlUser=my-user,mysqlPassword=my-password,mysqlDatabase=my-database \
    stable/mysql
```
