# Install a Solace PubSub+ Software Event Broker onto a Pivotal Container Service (PKS) cluster

## Purpose of this repository

This repository explains how to install a Solace PubSub+ Software Event Broker in various configurations onto a [Pivotal Container Service (PKS)](//cloud.vmware.com/pivotal-container-service ) cluster.

The recommended Solace PubSub+ Software Event Broker version is 9.3 or later.

For deploying Solace PubSub+ Software Event Broker in a generic Kubernetes environment, refer to the [Solace Kubernetes Quickstart project](//github.com/SolaceProducts/solace-kubernetes-quickstart ).

## Description of the Solace PubSub+ Software Event Broker

The Solace PubSub+ software event broker meets the needs of big data, cloud migration, and Internet-of-Things initiatives, and enables microservices and event-driven architecture. Capabilities include topic-based publish/subscribe, request/reply, message queues/queueing, and data streaming for IoT devices and mobile/web apps. The event broker supports open APIs and standard protocols including AMQP, JMS, MQTT, REST, and WebSocket. Moreover, it can be deployed in on-premise datacenters, natively within private and public clouds, and across complex hybrid cloud environments.

Solace PubSub+ software event brokers can be deployed in either a 3-node High-Availability (HA) cluster, or as a single-node non-HA deployment. For simple test environments that need only to validate application functionality, a single instance will suffice. Note that in production, or any environment where message loss cannot be tolerated, an HA cluster is required.

## How to deploy an event broker onto PKS

In this quick start we go through the steps to set up an event broker either as a single-node instance (default settings), or in a 3-node HA cluster.

### Step 1: Access to PKS

Perform any prerequisites to access PKS v1.4 or later in your target environment. For specific details, refer to your PKS platform's documentation.

Tasks may include:

* Getting access to a platform which supports PKS, such as VMware Enterprise PKS
* Install Kubernetes [`kubectl`](//kubernetes.io/docs/tasks/tools/install-kubectl/ ) tool.
* Install the PKS CLI client and log in.
* Create a PKS cluster (for CPU and memory requirements of your Solace event broker target deployment configuration, refer to the [Deployment Configurations](#event-broker-deployment-configurations) section)
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

### Step 3 (Optional): Load the PubSub+ Docker image to a private Docker image registry

**Hint:** You may skip the rest of this step if not using a private Docker image registry (Harbor). The free PubSub+ Standard Edition is available from the [public Docker Hub registry](//hub.docker.com/r/solace/solace-pubsub-standard/tags/ ), the image reference is `solace/solace-pubsub-standard:<TagName>`.

To get the PubSub+ event broker Docker image URL, go to the Solace Developer Portal and download the Solace PubSub+ software event broker as a **docker** image or obtain your version from Solace Support.

| PubSub+ Standard<br/>Docker Image | PubSub+ Enterprise Evaluation Edition<br/>Docker Image
| :---: | :---: |
| Free, up to 1k simultaneous connections,<br/>up to 10k messages per second | 90-day trial version, unlimited |
| [Download Standard docker image](http://dev.solace.com/downloads/ ) | [Download Evaluation docker image](http://dev.solace.com/downloads#eval ) |

If using Harbor for private Docker registry, use the `upload_harbor.sh` script provided in the `scripts` directory. You can pass the PubSub+ image reference as a public Docker image location or a Http download Url (the PubSub+ image `md5` checksum must also be available from the Http download Url). Also provide the Harbor host and project names and additionally, if using signed images set the `DOCKER_CONTENT_TRUST=1` and `DOCKER_CONTENT_TRUST_SERVER` environment variables. Check the script inline comments for defaults.

Note: Ensure the project with a user configured exists in Harbor, Docker is logged in to the Harbor server as user, as well as Docker Notary is configured for Harbor if using signed images. Consult your Harbor documentation for details. 

```sh
cd ~/workspace/solace-pks/scripts
# Define variables up-front to be passed to the "upload_harbor" script:
[PUBSUBPLUS_IMAGE_URL=<docker-repo-or-download-link>] \
  HARBOR_HOST=<hostname> \
  [HARBOR_PROJECT=<project>] \
  [DOCKER_CONTENT_TRUST=[0|1] \
  [DOCKER_CONTENT_TRUST_SERVER=<full-server-url-with-port>] \
  upload_harbor.sh
## Example-1: upload the latest from Docker Hub to Harbor
HARBOR_HOST=<harbor-server> ./upload_harbor.sh
## Example-2: upload from a Http Url to Harbor
HARBOR_HOST=<harbor-server> \
PUBSUBPLUS_IMAGE_URL=https://<server-location>/solace-pubsub-standard-9.1.0.118-docker.tar.gz ./upload_harbor.sh
```

To load the PubSub+ Docker image into other private Docker registry, follow the general steps below; for specifics, consult the documentation of the registry you are using.

* Prerequisite: local installation of [Docker](//docs.docker.com/get-started/ ) is required
* First load the image to the local docker registry:
```sh
# Option a): If you have a local tar.gz Docker image file
sudo docker load -i <solace-pubsub-XYZ-docker>.tar.gz
# Option b): You can use the public PubSub+ Docker image from Docker Hub
sudo docker pull solace/solace-pubsub-standard:latest # or specific <TagName>

# Verify the image has been loaded and note the associated "IMAGE ID"
sudo docker images
```
* Login to the private registry:
```sh
sudo docker login <private-registry> ...
```
* Tag the image with the desired name and tag:
```sh
sudo docker tag <image-id> <private-registry>/<path>/<image-name>:<tag>
```
* Push the image to the private registry
```sh
sudo docker push <private-registry>/<path>/<image-name>:<tag>
```

Note that additional steps may be required if using signed images.


### Step 4: Deploy the event broker

#### Overview

A deployment is defined by a "Helm chart", which consists of templates and values. The *values* specify the particular configuration properties in the templates. The generic [Solace Kubernetes Quickstart project](//github.com/SolaceProducts/solace-kubernetes-quickstart#step-4 ) provides additional details about the templates used.

For the "pubsubplus" Helm chart the default *values* are in the `values.yaml` file located in the `pubsubplus` directory:
```sh
cd ~/workspace/solace-pks
more pubsubplus/values.yaml
``` 

For all value configuration properties, refer to the documentation of the [Helm Chart Configuration](pubsubplus#helm-chart-configuration)

When Helm is used to install a deployment, the configuration properties can be set in several ways, in combination of the followings:

* If no other values-file or override is specified, settings from the local `values.yaml` in the chart directory is used.
```sh
  # <chart-location>: directory path, url or Helm repo reference to the chart
  helm install <chart-location>
```
* The default `values.yaml` can be overlayed by one or more specified values-files; each additional file overrides settings in the previous one. A values file may also define only a subset of values.
```sh
  # <my-values-file>: directory path to a values file
  helm install -f <my-values-file1>[ -f <my-values-file2>] <chart-location>
```
* Explicitly overriding configuration properties:
```sh
  # overrides the settings in values.yaml in the chart directory, can pass multiple params
  helm install <chart-location> --set <param1>=<value1>[,<param2>=<value2>]
```

Helm will autogenerate a release name if not specified (in this document a PubSub+ "deployment" and a Helm "release" are used interchangeably). Here is how to specify a release name:
```sh
  # Helm will reference this deployment as "my-pubsubplus-ha-release"
  helm install --name my-pubsubplus-ha-release <chart-location>
```

<br/>
Now check for dependencies before going ahead with a deployment: your deployment may depend on the presence of Kubernetes objects, such as a StorageClass and ImagePullSecrets. These need to be created first if required.

#### Ensure a StorageClass is available

The PubSub+ deployment uses disk storage for logging, configuration, guaranteed messaging and other purposes. The use of a persistent storage is recommended, otherwise if a pod-local storage is used data will be lost with the loss of a pod.

A [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/ ) is used to obtain a persistent storage that is external to the pod.

For a list of of available StorageClasses, execute
```sh
kubectl get storageclass
```

It is expected that there is at least one StorageClass available. Unless otherwise configured, the "pubsubplus" chart will try to use the PKS environment default StorageClass - define the `storage.useStorageClass` value if necessary.

Refer to your PKS environment's documentation if a StorageClass needs to be created or to understand the differences if there are multiple options.


#### Create and use ImagePullSecrets for signed images

ImagePullSecrets may be required if using signed images from a private Docker registry, including Harbor.

Here is an example of creating an ImagePullSecret. Refer to your registry's documentation for the specific details of use.

```sh
kubectl create secret docker-registry <pull-secret-name> --dockerserver=<private-registry-server> \
  --docker-username=<registry-user-name> --docker-password=<registry-user-password> \
  --docker-email=<registry-user-email>
```

Then set the `image.pullSecretName` value to `<pull-secret-name>`.

#### Use Helm to install the deployment

There are two options to use the "pubsubplus" Helm chart:

a) From a local clone of this GitHub project; or
<br/>
b) From a Helm Chart Repository.

The following non-HA and HA deployment examples use option a), a local clone.

If using a Helm Chart Repository, such as Harbor, first package the "pubsubplus" Helm chart and load it into your Helm Chart Repository. 
```sh
cd ~/workspace/solace-pks
# Create a package
helm package pubsubplus

# Refer to your Repository's documentation how to load the chart
:
``` 

Then replace `pubsubplus` in the following examples with the path of the "pubsubplus" chart in your Repository:
```
# No need to cd ~/workspace/solace-pks, can be executed from anywhere
helm install pubsubplus ... ===> helm install <repo>/<path-of-the-pubsubplus-chart> ...
```

##### Single-node non-HA deployment

The default values in the `values.yaml` file in this repo configure a small single-node deployment (`redundancy: false`) with up to 100 connections (`size: prod100`).

```sh
# non-HA deployment
cd ~/workspace/solace-pks
# Use contents of default values.yaml and override redundancy (if needed) and the admin password
helm install pubsubplus --name my-pubsubplus-nonha-release \
               --set solace.redundancy=false,solace.usernameAdminPassword=Ch@ngeMe
# Wait until the pod is running and ready and the active event broker pod label is "active=true"
watch kubectl get pods --show-labels
```

##### HA deployment

The only difference to the non-HA deployment in the simple case is to set `solace.redundancy=true`.

```sh
# HA deployment
cd ~/workspace/solace-pks
# Use contents of values.yaml and override redundancy (if needed) and the admin password
helm install pubsubplus --name my-pubsubplus-ha-release \
               --set solace.redundancy=true,solace.usernameAdminPassword=Ch@ngeMe
# Wait until all pods running and ready and the active event broker pod label is "active=true"
watch kubectl get pods --show-labels
```

To modify a deployment, refer to section [Repairing, Modifying or Upgrading the event broker cluster](#SolClusterModifyUpgrade ). If you need to start over then refer to section [Deleting a deployment](#deleting-a-deployment).

### Validate the Deployment

Now you can validate your deployment on the command line. In this example an HA cluster is deployed with pod/XXX-XXX-pubsubplus-0 being the active event broker/pod. The notation XXX-XXX is used for the unique release name, e.g: "my-pubsubplus-ha-release".

```sh
prompt:~$ kubectl get statefulsets,services,pods,pvc,pv
NAME                                  READY   AGE
statefulset.apps/XXX-XXX-pubsubplus   3/3     9m57s

NAME                               TYPE           CLUSTER-IP       EXTERNAL-IP       PORT(S)                                                                                                                AGE
service/kubernetes                 ClusterIP      10.100.200.1     <none>            443/TCP                                                                                                                24d
service/XXX-XXX-pubsubplus             LoadBalancer   10.100.200.209   104.197.193.161   22:32650/TCP,8080:31816/TCP,55555:31692/TCP,55003:32625/TCP,55443:32588/TCP,943:30580/TCP,80:30672/TCP,443:32736/TCP   9m57s
service/XXX-XXX-pubsubplus-discovery   ClusterIP      None             <none>            8080/TCP                                                                                                               9m57s

NAME                       READY   STATUS    RESTARTS   AGE
pod/XXX-XXX-pubsubplus-0   1/1     Running   0          9m57s
pod/XXX-XXX-pubsubplus-1   1/1     Running   0          9m57s
pod/XXX-XXX-pubsubplus-2   1/1     Running   0          9m57s

NAME                                              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/data-XXX-XXX-pubsubplus-0   Bound    pvc-3c294e76-860d-11e9-b50a-42010a000b26   20Gi       RWO            standard       9m57s
persistentvolumeclaim/data-XXX-XXX-pubsubplus-1   Bound    pvc-3c2c5d8b-860d-11e9-b50a-42010a000b26   20Gi       RWO            standard       9m57s
persistentvolumeclaim/data-XXX-XXX-pubsubplus-2   Bound    pvc-3c310ba4-860d-11e9-b50a-42010a000b26   20Gi       RWO            standard       9m57s

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                           STORAGECLASS   REASON   AGE
persistentvolume/pvc-3c294e76-860d-11e9-b50a-42010a000b26   20Gi       RWO            Delete           Bound    default/data-XXX-XXX-pubsubplus-0   standard                9m44s
persistentvolume/pvc-3c2c5d8b-860d-11e9-b50a-42010a000b26   20Gi       RWO            Delete           Bound    default/data-XXX-XXX-pubsubplus-1   standard                9m44s
persistentvolume/pvc-3c310ba4-860d-11e9-b50a-42010a000b26   20Gi       RWO            Delete           Bound    default/data-XXX-XXX-pubsubplus-2   standard                9m54s

prompt:~$ kubectl describe service XXX-XX-pubsubplus
Name:                     XXX-XXX-pubsubplus
Namespace:                default
Labels:                   app=pubsubplus
                          chart=pubsubplus-1.0.1
                          heritage=Tiller
                          release=XXX-XXX
Annotations:              <none>
Selector:                 active=true,app=pubsubplus,release=XXX-XXX
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

The most frequently used management and messaging service ports are exposed through a Load Balancer. In the above example `104.197.193.161` is the Load Balancer's external Public IP to use. If you need to expose additional ports refer to section [Modifying the Cluster](#SolClusterModify ).

## Gaining admin access to the event broker

Refer to the [Management Tools section](//docs.solace.com/Management-Tools.htm ) of the online documentation to learn more about the available admin tools. "Solace PubSub+ Manager" is recommended for manual administration tasks and the "SEMP API" for programmatic configuration.

### Solace PubSub+ Manager and SEMP API access

Use the Load Balancer's external Public IP at port 8080 to access these services.

### CLI access

You can SSH into the active event broker as the `admin` user using the Load Balancer's external Public IP:

```sh

$ssh -p 22 admin@104.197.193.161
Solace PubSub+ Standard
Password:

Solace PubSub+ Standard Version 9.1.0.117

The Solace PubSub+ Standard is proprietary software of
Solace Corporation. By accessing the Solace PubSub+ Standard
you are agreeing to the license terms and conditions located at
http://www.solace.com/license-software

Copyright 2004-2019 Solace Corporation. All rights reserved.

To purchase product support, please contact Solace at:
https://solace.com/contact-us/

Operating Mode: Message Routing Node

XXX-XXX-pubsubplus-0>
```

In an HA deployment, for CLI access to the individual event broker nodes use:

```sh
kubectl exec -it XXX-XXX-pubsubplus-<pod-ordinal> -- bash -c "ssh -p 2222 admin@localhost"
```

### PubSub+ nodes SSH access

For SSH access to individual event broker nodes use:

```sh
kubectl exec -it XXX-XXX-pubsubplus-<pod-ordinal> bash
```

## Viewing contrainer logs

Logs from the currently running container:

```sh
kubectl logs XXX-XXX-pubsubplus-0 -c solace   # add -f flag to follow real-time
```

Logs from the previously terminated container:

```sh
kubectl logs XXX-XXX-pubsubplus-0 -c solace -p
```

## Testing data access to the event broker

To test data traffic though the newly created event broker instance, visit the Solace Developer Portal and and select your preferred programming language in [APIs & Protocols](https://docs.solace.com/APIs.htm ). Under each language there is a Publish/Subscribe tutorial that will help you get started and provide the specific default port to use.

Use the external Public IP to access the cluster. If a port required for a protocol is not opened, refer to the next section on how to open it up by modifying the cluster.

## <a name="SolClusterModifyUpgrade"></a> Repairing, Modifying or Upgrading the event broker cluster

`helm upgrade <release-name> <chart-location>` can be used to adjust the deployment to a new set of values.

### Repairing the Cluster

To repair the deployment by recreating possibly missing artifacts including a deleted Service or StateFulSet, execute `helm upgrade` with the same set of values as used for `helm install`. Only the missing templates will be applied.

```sh
cd ~/workspace/solace-pks
helm upgrade XXXX-XXXX pubsubplus \
           [--set <settings-for-original-install>] \
           [-f <value-file-for-original-install>]
```

### <a name="SolClusterModify"></a> Modifying the Cluster

To modify deployment parameters, e.g. to add ports exposed via the loadbalancer, you need to upgrade the release with a new set of ports. In this example we will add the MQTT 1883 tcp port to the loadbalancer.

```sh
cd ~/workspace/solace-pks
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
helm upgrade XXXX-XXXX pubsubplus \
           [--set <settings-for-original-install>] \
           [-f <value-file-for-original-install>] \
           -f port-update.yaml
```

For information about ports used, refer to the [Solace documentation](//docs.solace.com/Configuring-and-Managing/Default-Port-Numbers.htm ).

Note: the cluster cannot be modified this way between non-HA and HA deployments, as well as scaling tiers.

### Upgrading the Cluster

To upgrade the version of the PubSub+ event broker Docker image running within a Kubernetes cluster:

- Add the new version of the event broker to your container registry.
- Create a simple upgrade.yaml file directory, and add it to the deployment, which will upgrade the pod or all pods in an HA deployment.:

```sh
cd ~/workspace/solace-pks
tee ./upgrade.yaml <<-EOF   # create update file with following contents:
image:
  repository: <repo>/<project>/solace-pubsub-standard
  tag: NEW.VERSION.XXXXX
  pullPolicy: IfNotPresent
EOF
helm upgrade XXXX-XXXX pubsubplus \
           [--set <settings-for-original-install>] \
           [-f <value-file-for-original-install>] \
           -f upgrade.yaml
```

## Deleting a deployment

Use Helm to delete a release:

```
helm delete XXX-XXX
```

Helm will not delete PersistentVolumeClaims and PersistentVolumes - they need to be cleaned up manually if no longer needed.

```
kubectl get pvc
# Delete all related pvc, which will clean up their used pv
```

Check what has remained from the deployment, which should only return a single line with svc/kubernetes and artifacts from other deployments, if applicable:

```
kubectl get statefulsets,services,pods,pvc,pv
NAME                           TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)         AGE
service/kubernetes             ClusterIP      XX.XX.XX.XX     <none>            443/TCP         XX
```

## Event Broker Deployment Configurations

The PubSub+ event broker can be deployed in following scaling (simultaneous connections):

    * `dev`: for development purposes only, no guaranteed performance. Minimum requirements: 1 CPU, 1 GB memory
    * `prod100`: up to 100 connections, minimum requirements: 2 CPU, 2 GB memory
    * `prod1k`: up to 1,000 connections, minimum requirements: 2 CPU, 4 GB memory
    * `prod10k`: up to 10,000 connections, minimum requirements: 4 CPU, 12 GB memory
    * `prod100k`: up to 100,000 connections, minimum requirements: 8 CPU, 28 GB memory
    * `prod200k`: up to 200,000 connections, minimum requirements: 12 CPU, 56 GB memory
    
Note: the free PubSub+ Standard Edition supports up to `prod1k`.

For the "pubsubplus" chart configuration values, refer to the documentation of the [Helm Chart Configuration](pubsubplus#helm-chart-configuration)

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

See the list of [contributors](//github.com/SolaceProducts/solace-pks/graphs/contributors) who participated in this project.

## License

This project is licensed under the Apache License, Version 2.0. - See the [LICENSE](LICENSE) file for details.

## Resources

For more information about Solace technology in general please visit these resources:

- The Solace Developer Portal website at: http://dev.solace.com
- Understanding [Solace technology.](http://dev.solace.com/tech/)
- Ask the [Solace community](http://dev.solace.com/community/).
