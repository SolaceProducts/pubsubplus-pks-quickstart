# Install a Solace PubSub+ Software Event Broker onto a Pivotal Container Service (PKS) cluster

## Purpose of this repository

This repository extends the [PubSub+ Kubernetes Quickstart](https://github.com/SolaceProducts/solace-kubernetes-quickstart ) to show you how to install a Solace PubSub+ Software Event Broker in various configurations onto a [Pivotal Container Service (PKS)](//cloud.vmware.com/pivotal-container-service ) cluster.

The recommended Solace PubSub+ Software Event Broker version is 9.3 or later.

## Description of the Solace PubSub+ Software Event Broker

The Solace PubSub+ software event broker meets the needs of big data, cloud migration, and Internet-of-Things initiatives, and enables microservices and event-driven architecture. Capabilities include topic-based publish/subscribe, request/reply, message queues/queueing, and data streaming for IoT devices and mobile/web apps. The event broker supports open APIs and standard protocols including AMQP, JMS, MQTT, REST, and WebSocket. Moreover, it can be deployed in on-premise datacenters, natively within private and public clouds, and across complex hybrid cloud environments.

## How to deploy an event broker onto PKS

The PubSub+ software event broker can be deployed in either a 3-node High-Availability (HA) cluster, or as a single-node non-HA deployment. For simple test environments that need only to validate application functionality, a single instance will suffice. Note that in production, or any environment where message loss cannot be tolerated, an HA cluster is required.

Detailed documentation of deploying the event broker in a general Kubernetes environment is provided in the [Solace PubSub+ Event Broker on Kubernetes Documentation](//github.com/SolaceDev/solace-kubernetes-quickstart/blob/HelmReorg/docs/PubSubPlusK8SDeployment.md).

Consult the [Deployment Considerations](https://github.com/SolaceDev/solace-kubernetes-quickstart/blob/HelmReorg/docs/PubSubPlusK8SDeployment.md#pubsub-event-broker-deployment-considerations) section of the Documentation when planning your deployment, then follow these steps to deploy.

### Step 1: Access to PKS

Perform any prerequisites to access PKS v1.4 or later from your command-line environment. For specific details, refer to your PKS platform's documentation.

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

Refer to the [Install and configure Helm](https://github.com/SolaceDev/solace-kubernetes-quickstart/tree/HelmReorg#2-install-and-configure-helm) section of the PubSub+ Kubernetes Quickstart.

<br>

### Step 3 (Optional): Load the PubSub+ Docker image to a private Docker image registry

**Hint:** You may skip the rest of this step if not using Harbor or other private Docker registry. The free PubSub+ Standard Edition is available from the [public Docker Hub registry](//hub.docker.com/r/solace/solace-pubsub-standard/tags/ ), the image reference is `solace/solace-pubsub-standard:<TagName>`.

To get the PubSub+ event broker Docker image URL, go to the Solace Developer Portal and download the Solace PubSub+ software event broker as a **docker** image or obtain your version from Solace Support.

| PubSub+ Standard<br/>Docker Image | PubSub+ Enterprise Evaluation Edition<br/>Docker Image
| :---: | :---: |
| Free, up to 1k simultaneous connections,<br/>up to 10k messages per second | 90-day trial version, unlimited |
| [Download Standard docker image](http://dev.solace.com/downloads/ ) | [Download Evaluation docker image](http://dev.solace.com/downloads#eval ) |

#### Loading the PubSub+ Docker image to Harbor

If using Harbor for private Docker registry, use the `upload_harbor.sh` script from this repo.

Prerequisites:
* Local installation of [Docker](//docs.docker.com/get-started/ ) is required
* Project with a user configured exists in Harbor
* Docker is logged in to the Harbor server as user
* Docker Notary is configured for Harbor if using signed images. Consult your Harbor documentation for details.

Script options and arguments:
* PUBSUBPLUS_IMAGE_URL: You can pass the PubSub+ image reference as a public Docker image location (default is `solace/solace-pubsub-standard:latest`) or a Http download Url (the PubSub+ image `md5` checksum must also be available from the Http download Url).
* HARBOR_HOST: hostname of the Harbor server
* HARBOR_PROJECT: configured project name on the Harbor server
* DOCKER_CONTENT_TRUST: if using signed images set the `DOCKER_CONTENT_TRUST=1`
* DOCKER_CONTENT_TRUST_SERVER: also set if using signed images

```sh
wget https://raw.githubusercontent.com/SolaceProducts/solace-pks/master/scripts/upload_harbor.sh
chmod +x upload_harbor.sh
# Define variables up-front to be passed to the "upload_harbor" script:
[PUBSUBPLUS_IMAGE_URL=<docker-repo-or-download-link>] \
  HARBOR_HOST=<hostname> \
  [HARBOR_PROJECT=<project>] \
  [DOCKER_CONTENT_TRUST=[0|1] \
  [DOCKER_CONTENT_TRUST_SERVER=<full-server-url-with-port>] \
  ./upload_harbor.sh
## Example-1: upload the latest from Docker Hub to Harbor
HARBOR_HOST=<harbor-server> ./upload_harbor.sh
## Example-2: upload from a Http Url to Harbor
HARBOR_HOST=<harbor-server> \
PUBSUBPLUS_IMAGE_URL=https://<server-location>/solace-pubsub-standard-9.4.0.118-docker.tar.gz ./upload_harbor.sh
```

Note that additional steps may be required if using signed images - follow the prompts.

The script will end with showing the "Harbor image location" in `<your-image-location>:<your-image-tag>` format and this shall be passed to the PubSub+ deployment parameters `image.repository` and `image.tag` respectively.

For general additional information, refer to the [Using private registries](https://github.com/SolaceDev/solace-kubernetes-quickstart/blob/HelmReorg/docs/PubSubPlusK8SDeployment.md#using-private-registries) section in the PubSub+ Kubernetes Documentation.

### Step 4: Deploy the event broker

From here follow the steps in [the PubSub+ Kubernetes Quickstart](//github.com/SolaceDev/solace-kubernetes-quickstart/tree/HelmReorg#2-install-and-configure-helm) to deploy a single-node or an HA event broker.

Refer to the detailed PubSub+ Kubernetes documentation for:
* [Validating the deployment](//github.com/SolaceDev/solace-kubernetes-quickstart/blob/HelmReorg/docs/PubSubPlusK8SDeployment.md#validating-the-deployment); or
* [Troubleshooting](//github.com/SolaceDev/solace-kubernetes-quickstart/blob/HelmReorg/docs/PubSubPlusK8SDeployment.md#troubleshooting)
* [Modifying or Upgrading](//github.com/SolaceDev/solace-kubernetes-quickstart/blob/HelmReorg/docs/PubSubPlusK8SDeployment.md#modifying-or-upgrading-a-deployment)
* [Deleting the deployment](//github.com/SolaceDev/solace-kubernetes-quickstart/blob/HelmReorg/docs/PubSubPlusK8SDeployment.md#deleting-a-deployment)

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
