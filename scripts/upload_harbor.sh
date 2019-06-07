#!/bin/bash
set -e

SOLACE_EDITION="${SOLACE_EDITION:-standard}"
DOCKER_SOLACE_TAG="${DOCKER_SOLACE_TAG:-latest}"
HARBOR_HOST="$HARBOR_HOST"
HARBOR_PROJECT="${HARBOR_PROJECT:-solace}"
DOCKER_CONTENT_TRUST="${DOCKER_CONTENT_TRUST:-0}"
export DOCKER_CONTENT_TRUST_SERVER="${DOCKER_CONTENT_TRUST_SERVER:-https://${HARBOR_HOST}:4443}"

echo "SOLACE_EDITION=$SOLACE_EDITION"
echo "DOCKER_SOLACE_TAG=$DOCKER_SOLACE_TAG"
echo "HARBOR_HOST=$HARBOR_HOST"
echo "HARBOR_PROJECT=$HARBOR_PROJECT"
echo "DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST"
echo "DOCKER_CONTENT_TRUST_SERVER=$DOCKER_CONTENT_TRUST_SERVER"

echo
echo "#############################################################"
echo "Pushing solace-pubsub-${SOLACE_EDITION} to harbor (${HARBOR_HOST}/${HARBOR_PROJECT})"
echo

if [[ -n "$HARBOR_HOST" ]]; then
	docker_hub_solace="solace/solace-pubsub-${SOLACE_EDITION}:${DOCKER_SOLACE_TAG}"
	docker_harbor_solace="${HARBOR_HOST}/${HARBOR_PROJECT}/solace-pubsub-${SOLACE_EDITION}:${DOCKER_SOLACE_TAG}"

	DOCKER_CONTENT_TRUST=0 docker pull "$docker_hub_solace"
	docker tag "$docker_hub_solace" "$docker_harbor_solace"
	docker push "$docker_harbor_solace"
else
	>&2 echo "HARBOR_HOST must be defined, cannot push image to Harbor"
	exit 1
fi
