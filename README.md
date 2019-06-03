# Install a Solace PubSub+ Software Message Broker onto a Pivotal Container Service (PKS) cluster

## Purpose of this repository

This repository explains how to install a Solace PubSub+ Software Message Broker in various configurations onto a [Pivotal Container Service (PKS)](//cloud.vmware.com/pivotal-container-service ) cluster.

The recommended Solace PubSub+ Software Message Broker version is 9.1 or later.

For deploying Solace PubSub+ Software Message Broker in a generic Kubernetes environment, refer to the [Solace Kubernetes Quickstart project](//github.com/SolaceProducts/solace-kubernetes-quickstart ).

## Description of the Solace PubSub+ Software Message Broker

The Solace PubSub+ software message broker meets the needs of big data, cloud migration, and Internet-of-Things initiatives, and enables microservices and event-driven architecture. Capabilities include topic-based publish/subscribe, request/reply, message queues/queueing, and data streaming for IoT devices and mobile/web apps. The message broker supports open APIs and standard protocols including AMQP, JMS, MQTT, REST, and WebSocket. Moreover, it can be deployed in on-premise datacenters, natively within private and public clouds, and across complex hybrid cloud environments.

Solace PubSub+ software message brokers can be deployed in either a 3-node High-Availability (HA) cluster, or as a single-node non-HA deployment. For simple test environments that need only to validate application functionality, a single instance will suffice. Note that in production, or any environment where message loss cannot be tolerated, an HA cluster is required.

## How to deploy a message broker onto PKS

In this quick start we go through the steps to set up a message broker either as a single-node instance (default settings), or in a 3-node HA cluster.

### Step 1: Access to PKS

Perform any prerequisites to access PKS v1.4 or later in your target environment. For specific details, refer to your PKS platform's documentation.

Tasks may include:

* Getting access to a platform which supports PKS, such as VMware Enterprise PKS
* Install Kubernetes [`kubectl`](//kubernetes.io/docs/tasks/tools/install-kubectl/ ) tool.
* Install the PKS CLI client and log in.
* Create a PKS cluster (for CPU and memory requirements of your Solace message broker target deployment configuration, refer to the [Deployment Configurations](#message-broker-deployment-configurations) section)
* Configure any necessary environment settings and install certificates
* Fetch the credentials for the PKS cluster
* Perform any necessary setup and configure access if using a private Docker image registry, such as Harbor
* Perform any necessary setup and configure access if using a Helm chart repository, such as Harbor

Verify access to your PKS cluster and the available nodes by running `kubectl get nodes -o wide` from your environment.

### Step 2: Deploy Helm package manager

We recommend using the [Kubernetes Helm](//github.com/kubernetes/helm/blob/master/README.md ) tool to manage the deployment.

This GitHub repo provides a helper script which will install, setup and configure Helm in your environment if not already there.

Clone this repo and execute the `setup_helm` script:
```sh
mkdir ~/workspace; cd ~/workspace
git clone //github.com/SolaceProducts/solace-pks.git
cd solace-pks    # repo root directory
./scripts/setup_helm.sh
```

### Step 3 (Optional): Load the Solace Docker image to a private Docker image registry

**Hint:** You may skip the rest of this step if not using a private Docker image registry (Harbor). The free PubSub+ Standard Edition is available from the [public Docker Hub registry](//hub.docker.com/r/solace/solace-pubsub-standard/tags/ ). For public Docker Hub the docker registry reference to use will be `solace/solace-pubsub-standard:<TagName>`.

To get the Solace message broker Docker image, go to the Solace Developer Portal and download the Solace PubSub+ software message broker as a **docker** image or obtain your version from Solace Support.

| PubSub+ Standard<br/>Docker Image | PubSub+ Enterprise Evaluation Edition<br/>Docker Image
| :---: | :---: |
| Free, up to 1k simultaneous connections,<br/>up to 10k messages per second | 90-day trial version, unlimited |
| [Download Standard docker image](http://dev.solace.com/downloads/ ) | [Download Evaluation docker image](http://dev.solace.com/downloads#eval ) |

To load the Docker image tar archive file into a docker registry, follow the steps specific to the registry you are using.

This is a general example:
* Local installation of [`docker`](//docs.docker.com/get-started/ ) is required
* First load the image to the local docker registry:
```
# Option a): If you have a tar.gz Docker image file
sudo docker load -i <solace-pubsub-XYZ-docker>.tar.gz
# Option b): You can use the public Solace Docker image from Docker Hub
sudo docker pull solace/solace-pubsub-standard:latest # or specific <TagName>

# Verify image has been loaded, note the "IMAGE ID"
sudo docker images
```
* Login to the private registry
`sudo docker login <private-registry> ...`
* Tag the image with the desired name and tag
`sudo docker tag <image-id> <private-registry>/<path>/<image-name>:<tag>`
* Push the image to the private registry
`sudo docker push <private-registry>/<path>/<image-name>:<tag>`

Note that additional steps may be required if using signed images.


### Step 4: Deploy message broker Pods and Service to the cluster

#### Overview

A deployment is defined by a "Helm chart", which consists of templates and values. The values specify the particular configuration properties in the templates. The generic [Solace Kubernetes Quickstart project](//github.com/SolaceProducts/solace-kubernetes-quickstart#step-4 ) provides additional details about the templates used.

For the "solace" Helm chart the default values are in the `values.yaml` file located in the `solace` directory:
```sh
cd ~/workspace/solace-pks
more solace/values.yaml
``` 

For a description of all value configuration properties, refer to section [Solace Helm Chart Configuration](#SolaceHelmChartConfig)

When Helm is used to install a deployment the configuration properties can be set in several ways, in combination of the followings:

* By default, if no other values-file or override is specified, settings from the `values.yaml` in the chart directory is used.
```sh
  # <chart-location>: directory path, url or Helm repo reference to the chart
  helm install <chart-location>
```
* The default `values.yaml` can be overlayed by one or more specified values-files; each additional file overrides settings in the previous one. A values file may define only a subset of values.
```sh
  # <my-values-file>: directory path to a values file
  helm install -f <my-values-file1>[ -f <my-values-file2>] <chart-location>
```
* Explicitly overriding settings
```sh
  # overrides the setting in values.yaml in the chart directory, can pass multiple
  helm install <chart-location> --set <param1>=<value1>[,<param2>=<value2>]
```

Helm will autogenerate a release name if not specified. Here is how to specify a release name:
```sh
  # Helm will reference this deployment as "my-solace-ha-release"
  helm install --name my-solace-ha-release <chart-location>
```

Check for dependencies before going ahead with a deployment: the Solace deployment may depend on the presence of Kubernetes objects, such as a StorageClass and ImagePullSecrets. These need to be created first if required.

#### Ensure a StorageClass is available

The Solace deployment uses disk storage for logging, configuration, guaranteed messaging and other purposes. The use of a persistent storage is recommended, otherwise data will be lost with the loss of a pod.

A [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/ ) is used to obtain persistent storage from outside the pod.

For a list of of available StorageClasses, execute
```sh
kubectl get storageclass
```

It is expected that there is at least one StorageClass available. By default, the "solace" chart assumes the name `standard`, adjust the `storage.useStorageClass` value if necessary.

Refer to your PKS environment's documentation if a StorageClass needs to be created or to understand the differences if there are multiple options.


#### Create and use ImagePullSecrets for signed images

ImagePullSecrets may be required if using signed images from a private Docker registry, including Harbor.

Here is an example of creating a secret. Refer to your registry's documentation for the specific details of use.

```sh
kubectl create secret docker-registry <pull-secret-name> --dockerserver=<private-registry-server> \
  --docker-username=<registry-user-name> --docker-password=<registry-user-password> \
  --docker-email=<registry-user-email>
```

Then set the `image.pullSecretName` value to `<pull-secret-name>`.

#### Use Helm to install the deployment

##### Single-node non-HA deployment

The default values in the `values.yaml` file in this repo configure a small single-node deployment (`redundancy: false`) with up to 100 connections (`size: prod100`).

```sh
cd ~/workspace/solace-pks/solace
# Use contents of default values.yaml and override redundancy (if needed) and the admin password
helm install . --name my-solace-nonha-release \
               --set solace.redundancy=false,solace.usernameAdminPassword=Ch@ngeMe
# Wait until the pod is running and ready and the active message broker pod label is "active=true"
watch kubectl get pods --show-labels
```

##### HA deployment

The only difference to the non-HA deployment in the simple case is to set `solace.redundancy=true`.

```sh
cd ~/workspace/solace-pks/solace
# Use contents of values.yaml and override redundancy (if needed) and the admin password
helm install . --name my-solace-ha-release \
               --set solace.redundancy=true,solace.usernameAdminPassword=Ch@ngeMe
# Wait until all pods running and ready and the active message broker pod label is "active=true"
watch kubectl get pods --show-labels
```

To modify a deployment, refer to section [Upgrading/modifying the message broker cluster](#SolClusterModifyUpgrade ). If you need to start over then refer to section [Deleting a deployment](#deleting-a-deployment).

### Validate the Deployment

Now you can validate your deployment on the command line. In this example an HA cluster is deployed with po/XXX-XXX-solace-0 being the active message broker/pod. The notation XXX-XXX is used for the unique release name, e.g: "my-solace-ha-release".

```sh
prompt:~$ kubectl get statefulsets,services,pods,pvc,pv
NAME                              READY   AGE
statefulset.apps/XXX-XXX-solace   3/3     9m57s

NAME                               TYPE           CLUSTER-IP       EXTERNAL-IP       PORT(S)                                                                                                                AGE
service/kubernetes                 ClusterIP      10.100.200.1     <none>            443/TCP                                                                                                                24d
service/XXX-XXX-solace             LoadBalancer   10.100.200.209   104.197.193.161   22:32650/TCP,8080:31816/TCP,55555:31692/TCP,55003:32625/TCP,55443:32588/TCP,943:30580/TCP,80:30672/TCP,443:32736/TCP   9m57s
service/XXX-XXX-solace-discovery   ClusterIP      None             <none>            8080/TCP                                                                                                               9m57s

NAME                   READY   STATUS    RESTARTS   AGE
pod/XXX-XXX-solace-0   1/1     Running   0          9m57s
pod/XXX-XXX-solace-1   1/1     Running   0          9m57s
pod/XXX-XXX-solace-2   1/1     Running   0          9m57s

NAME                                          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/data-XXX-XXX-solace-0   Bound    pvc-3c294e76-860d-11e9-b50a-42010a000b26   20Gi       RWO            standard       9m57s
persistentvolumeclaim/data-XXX-XXX-solace-1   Bound    pvc-3c2c5d8b-860d-11e9-b50a-42010a000b26   20Gi       RWO            standard       9m57s
persistentvolumeclaim/data-XXX-XXX-solace-2   Bound    pvc-3c310ba4-860d-11e9-b50a-42010a000b26   20Gi       RWO            standard       9m57s

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                           STORAGECLASS   REASON   AGE
persistentvolume/pvc-3c294e76-860d-11e9-b50a-42010a000b26   20Gi       RWO            Delete           Bound    default/data-XXX-XXX-solace-0   standard                9m44s
persistentvolume/pvc-3c2c5d8b-860d-11e9-b50a-42010a000b26   20Gi       RWO            Delete           Bound    default/data-XXX-XXX-solace-1   standard                9m44s
persistentvolume/pvc-3c310ba4-860d-11e9-b50a-42010a000b26   20Gi       RWO            Delete           Bound    default/data-XXX-XXX-solace-2   standard                9m54s

prompt:~$ kubectl describe service XXX-XX-solace
Name:                     XXX-XXX-solace
Namespace:                default
Labels:                   app=solace
                          chart=solace-1.0.1
                          heritage=Tiller
                          release=XXX-XXX
Annotations:              <none>
Selector:                 active=true,app=solace,release=XXX-XXX
Type:                     LoadBalancer
IP:                       10.100.200.209
LoadBalancer Ingress:     104.197.193.161
Port:                     ssh  22/TCP
TargetPort:               2222/TCP
NodePort:                 ssh  32650/TCP
Endpoints:                10.200.9.25:2222
Port:                     semp  8080/TCP
TargetPort:               8080/TCP
NodePort:                 semp  31816/TCP
Endpoints:                10.200.9.25:8080
Port:                     smf  55555/TCP
TargetPort:               55555/TCP
NodePort:                 smf  31692/TCP
Endpoints:                10.200.9.25:55555
:
:
```

The most frequently used service ports including management and messaging are exposed through a Load Balancer. In the above example `104.197.193.161` is the Load Balancer's external Public IP to use. If you need to expose additional ports refer to section [Modifying/upgrading the message broker cluster](#SolClusterModifyUpgrade ).

## Gaining admin access to the message broker

Refer to the [Management Tools section](//docs.solace.com/Management-Tools.htm ) of the online documentation to learn more about the available tools. The Solace PubSub+ Manager is recommended for manual administration tasks and SEMP API for programmatic configuration.

### Solace PubSub+ Manager and SEMP API access

Use the Load Balancer's external Public IP at port 8080 to access these services.

### Solace CLI access

If you are using a single message broker and are used to working with a CLI message broker console access, you can SSH into the message broker as the `admin` user using the Load Balancer's external Public IP:

```sh

$ssh -p 22 admin@104.197.193.161
Solace PubSub+ Standard
Password:

Solace PubSub+ Standard Version 8.10.0.1057

The Solace PubSub+ Standard is proprietary software of
Solace Corporation. By accessing the Solace PubSub+ Standard
you are agreeing to the license terms and conditions located at
http://www.solace.com/license-software

Copyright 2004-2018 Solace Corporation. All rights reserved.

To purchase product support, please contact Solace at:
http://dev.solace.com/contact-us/

Operating Mode: Message Routing Node

XXX-XXX-solace-0>
```

If you are using an HA cluster, it is better to access the CLI through the Kubernets pod and not directly via SSH.

Note: SSH access to the pod has been configured at port 2222. For external access SSH has been configured to to be exposed at port 22 by the load balancer.

* Loopback to SSH directly on the pod

```sh
kubectl exec -it XXX-XXX-solace-0  -- bash -c "ssh -p 2222 admin@localhost"
```

* Loopback to SSH on your host with a port-forward map

```sh
kubectl port-forward XXX-XXX-solace-0 62222:2222 &
ssh -p 62222 admin@localhost
```

This can also be mapped to individual message brokers in the cluster via port-forward:

```
kubectl port-forward XXX-XXX-solace-0 8081:8080 &
kubectl port-forward XXX-XXX-solace-1 8082:8080 &
kubectl port-forward XXX-XXX-solace-2 8083:8080 &
```

For SSH access to individual message brokers use:

```sh
kubectl exec -it XXX-XXX-solace-<pod-ordinal> -- bash
```

## Viewing logs
Logs from the currently running container:

```sh
kubectl logs XXX-XXX-solace-0 -c solace
```

Logs from the previously terminated container:

```sh
kubectl logs XXX-XXX-solace-0 -c solace -p
```

## Testing data access to the message broker

To test data traffic though the newly created message broker instance, visit the Solace Developer Portal and and select your preferred programming language in [send and receive messages](http://dev.solace.com/get-started/send-receive-messages/). Under each language there is a Publish/Subscribe tutorial that will help you get started and provide the specific default port to use.

Use the external Public IP to access the cluster. If a port required for a protocol is not opened, refer to the next section on how to open it up by modifying the cluster.

## <a name="SolClusterModifyUpgrade"></a> Modifying/upgrading the message broker cluster

To upgrade/modify the message broker cluster, make the required modifications to the chart in the `solace-kubernetes-quickstart/solace` directory as described next, then run the Helm tool from here. When passing multiple `-f <values-file>` to Helm, the override priority will be given to the last (right-most) file specified.

### Modifying the cluster

To **modify** other deployment parameters, e.g. to change the ports exposed via the loadbalancer, you need to upgrade the release with a new set of ports. In this example we will add the MQTT 1883 tcp port to the loadbalancer.

```
cd ~/workspace/solace-kubernetes-quickstart/solace
tee ./port-update.yaml <<-EOF   # create update file with following contents:
service:
  addExternalPort:
    - port: 1883
      protocol: TCP
      name: mqtt
      targetport: 1883
  addInternalPort:
    - port: 1883
      protocol: TCP
EOF
helm upgrade  XXXX-XXXX . --values values.yaml --values port-update.yaml
```

For information about ports used refer to the [Solace documentation](//docs.solace.com/Configuring-and-Managing/Default-Port-Numbers.htm )

### Upgrading the cluster

To **upgrade** the version of the message broker running within a Kubernetes cluster:

- Add the new version of the message broker to your container registry.
- Create a simple upgrade.yaml file in solace-kubernetes-quickstart/solace directory, e.g.:

```sh
image:
  repository: <repo>/<project>/solace-pubsub-standard
  tag: NEW.VERSION.XXXXX
  pullPolicy: IfNotPresent
```
- Upgrade the Kubernetes release, this will not effect running instances

```sh
cd ~/workspace/solace-kubernetes-quickstart/solace
helm upgrade XXX-XXX . -f values.yaml -f upgrade.yaml
```

- Delete the pod(s) to force them to be recreated with the new release. 

```sh
kubectl delete po/XXX-XXX-solace-<pod-ordinal>
```
> Important: In an HA deployment, delete the pods in this order: 2,1,0 (i.e. Monitoring Node, Backup Messaging Node, Primary Messaging Node). Confirm that the message broker redundancy is up and reconciled before deleting each pod - this can be verified using the CLI `show redundancy` and `show config-sync` commands on the message broker, or by grepping the message broker container logs for `config-sync-check`.

## Deleting a deployment

Use Helm to delete a deployment, also called a release:

```
helm delete XXX-XXX
```

Helm will not delete PersistentVolumeClaims and PersistentVolumes - they need to be cleaned up manually if no longer needed.

```
kubectl get pvc
# Delete all related pvc
```

Check what has remained from the deployment, which should only return a single line with svc/kubernetes and other unrelated artifacts if applicable:

```
kubectl get statefulsets,services,pods,pvc,pv
NAME                           TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)         AGE
service/kubernetes             ClusterIP      XX.XX.XX.XX     <none>            443/TCP         XX
```

## Message Broker Deployment Configurations

The solace mesage broker can be deployed in following scaling:

    * `dev`: for development purposes, no guaranteed performance. Minimum requirements: 1 CPU, 1 GB memory
    * `prod100`: up to 100 connections, minimum requirements: 2 CPU, 2 GB memory
    * `prod1k`: up to 1,000 connections, minimum requirements: 2 CPU, 4 GB memory
    * `prod10k`: up to 10,000 connections, minimum requirements: 4 CPU, 12 GB memory
    * `prod100k`: up to 100,000 connections, minimum requirements: 8 CPU, 28 GB memory
    * `prod200k`: up to 200,000 connections, minimum requirements: 12 CPU, 56 GB memory
    
<a name="SolaceHelmChartConfig"></a>
{% include_relative solace/README.md %}
Refer to [SolaceHelmChartConfig](./solace)

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](//github.com/SolaceProducts/solace-kubernetes-quickstart/graphs/contributors) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace technology in general please visit these resources:

- The Solace Developer Portal website at: http://dev.solace.com
- Understanding [Solace technology.](http://dev.solace.com/tech/)
- Ask the [Solace community](http://dev.solace.com/community/).
