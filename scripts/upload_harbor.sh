#!/bin/bash
set -e  # fail out in case of error encountered
## Params:
# PUBSUBPLUS_IMAGE_URL can be a Docker repo reference or a download URL
PUBSUBPLUS_IMAGE_URL="${PUBSUBPLUS_IMAGE_URL:-solace/solace-pubsub-standard:latest}"
# HARBOR_HOST is the fully qualified hostname of the Harbor server
HARBOR_HOST="$HARBOR_HOST"
# The Harbor project, default is "solace"
HARBOR_PROJECT="${HARBOR_PROJECT:-solace}"
# DOCKER_CONTENT_TRUST must be set to 1 if using signed images
export DOCKER_CONTENT_TRUST="${DOCKER_CONTENT_TRUST:-0}"
# DOCKER_CONTENT_TRUST_SERVER - use it for signed images, specify it if not https://${HARBOR_HOST}:4443
export DOCKER_CONTENT_TRUST_SERVER="${DOCKER_CONTENT_TRUST_SERVER:-https://${HARBOR_HOST}:4443}"
##
# Provide help if needed
if [ "$#" -gt  "0" ] ; then
  if [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then
    echo "Usage (define variables to be used for the script first as here):
    [PUBSUBPLUS_IMAGE_URL=<docker-repo-or-download-link>] \\
    HARBOR_HOST=<hostname> \\
    [HARBOR_PROJECT=<project>] \\
    [DOCKER_CONTENT_TRUST=[0|1] \\
    [DOCKER_CONTENT_TRUST_SERVER=<full-server-url-with-port>] \\
    upload_harbor.sh
    
    Check script inline comments for more details."
    exit 1
  else
    echo "Invalid argument(s), check -h or --help"
    exit 1
  fi
fi
# Check for minimum params
if [[ -z "$HARBOR_HOST" ]]; then
	>&2 echo "HARBOR_HOST must be defined, cannot push image to Harbor"
	exit 1
fi
echo "Using:"
echo "PUBSUBPLUS_IMAGE_URL=$PUBSUBPLUS_IMAGE_URL"
echo "HARBOR_HOST=$HARBOR_HOST"
echo "HARBOR_PROJECT=$HARBOR_PROJECT"
echo "DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST"
echo "DOCKER_CONTENT_TRUST_SERVER=$DOCKER_CONTENT_TRUST_SERVER"
echo
echo "#############################################################"
# Remove any existing PubSub+ image from local docker registry
if [ "`docker images | grep solace-`" ] ; then
  echo "Removing existing PubSub+ images from local docker repo"
  docker rmi -f `docker images | grep solace- | awk '{print $3}'` > /dev/null 2>&1
fi
# Loading provided PubSub+ image reference
echo "Trying to load ${PUBSUBPLUS_IMAGE_URL} into local Docker registry:"
if [ -z "`DOCKER_CONTENT_TRUST=0 docker pull ${PUBSUBPLUS_IMAGE_URL}`" ] ; then
  echo "Found that ${PUBSUBPLUS_IMAGE_URL} was not a docker registry uri, retrying if it is a download link"
  wget -q -O solos.info -nv  ${PUBSUBPLUS_IMAGE_URL}.md5
  IFS=' ' read -ra SOLOS_INFO <<< `cat solos.info`
  MD5_SUM=${SOLOS_INFO[0]}
  SolOS_LOAD=${SOLOS_INFO[1]}
  if [ -z ${MD5_SUM} ]; then
    echo "Missing md5sum for the PubSub+ load - exiting."
    exit 1
  fi
  echo "Reference md5sum is: ${MD5_SUM}"
  echo "Now downloading URL provided and validating"
  wget -q -O  ${SolOS_LOAD} ${PUBSUBPLUS_IMAGE_URL}
  ## Check MD5
  LOCAL_OS_INFO=`md5sum ${SolOS_LOAD}`
  
  IFS=' ' read -ra SOLOS_INFO <<< ${LOCAL_OS_INFO}
  LOCAL_MD5_SUM=${SOLOS_INFO[0]}
  if [ -z "${MD5_SUM}" ] || [ "${LOCAL_MD5_SUM}" != "${MD5_SUM}" ]; then
    echo "Possible corrupt PubSub+ load, md5sum do not match - exiting."
    exit 1
  else
    echo "Successfully downloaded ${SolOS_LOAD}"
  fi
  ## Load the image tarball
  docker load -i ${SolOS_LOAD}
fi
# Determine image details
PUBSUBPLUS_IMAGE_ID=`docker images | grep solace | awk '{print $3}'`
if [ -z "${PUBSUBPLUS_IMAGE_ID}" ] ; then
  echo "Could not load a valid PubSub+ docker image - exiting."
  exit 1
fi
echo "Loaded ${PUBSUBPLUS_IMAGE_URL} to local docker repo"
PUBSUBPLUS_IMAGE_NAME=`docker images | grep solace | awk '{split($0,a,"solace/"); print a[2]}' | awk '{print $1}'`
if [ -z $PUBSUBPLUS_IMAGE_NAME ] ; then PUBSUBPLUS_IMAGE_NAME=`docker images | grep solace | awk '{print $1}'`; fi
PUBSUBPLUS_IMAGE_TAG=`docker images | grep solace | awk '{print $2}'`
PUBSUBPLUS_HARBOR_IMAGE=${HARBOR_PROJECT}/${PUBSUBPLUS_IMAGE_NAME}:${PUBSUBPLUS_IMAGE_TAG}
# Tag and load to Harbor now
docker_harbor_pubsubplus="${HARBOR_HOST}/${PUBSUBPLUS_HARBOR_IMAGE}"
docker tag $PUBSUBPLUS_IMAGE_ID "$docker_harbor_pubsubplus"
docker push "$docker_harbor_pubsubplus" || { echo "Push to Harbor failed, ensure it is accessible and Docker is logged in with the correct user"; exit 1; }
echo "Success - Harbor image location: $docker_harbor_pubsubplus"
