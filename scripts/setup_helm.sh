#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# The purpose of this script is to:
#  - install the required version of helm

# kubectl installed is a pre-requisite
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists kubectl; then
  echo 'kubectl exists'
else
  echo 'kubectl not found on the PATH'
  echo '	Please install kubectl (see https://kubernetes.io/docs/tasks/tools/install-kubectl/)'
  echo '	Or if you have already installed it, add it to the PATH shell variable'
  echo "	Current PATH: ${PATH}"
  exit -1
fi

# Ensure helm is installed
os_type=`uname`
case ${os_type} in 
  "Darwin" )
    helm_type="darwin-amd64"
    helm_version="v2.14.0"
    archive_extension="tar.gz"
    sed_options="-E -i.bak"
    sudo_command="sudo"
    helm_target_location="/usr/bin"
    ;;
  "Linux" )
    helm_type="linux-amd64"
    helm_version="v2.14.0"
    archive_extension="tar.gz"
    sed_options="-i.bak"
    sudo_command="sudo"
    helm_target_location="/usr/bin"
    ;;
  *_NT* ) # BASH emulation on windows
    helm_type="windows-amd64"
    helm_version="v2.14.0"
    archive_extension="zip"
    sed_options="-i.bak"
    sudo_command=""
    helm_target_location="/usr/bin"
    ;;
esac
if exists helm; then
  echo "`date` INFO: Found helm $(helm version --client --short)"
elif [[ "$helm_type" != "windows-amd64" ]]; then
	pushd /tmp
	curl -O https://storage.googleapis.com/kubernetes-helm/helm-${helm_version}-${helm_type}.${archive_extension}
	tar zxf helm-${helm_version}-${helm_type}.${archive_extension} || unzip helm-${helm_version}-${helm_type}.${archive_extension}
	${sudo_command} mv ${helm_type}/helm* $helm_target_location
	popd
	echo "`date` INFO: Installed helm $(helm version --client --short)"
else
  echo 'helm not found on the PATH'
	echo "Automated install of helm is not supported on Windows. Please refer to https://github.com/helm/helm#install to install it manually then re-run this script."
	exit  -1
fi

# Deploy tiller
## code note: possible other option but then need to deal with installed helm : if [[ `helm init | grep "Tiller is already installed"` ]] ; then
if timeout 5s helm version --server --short >/dev/null 2>&1; then
  tiller_already_deployed=true
  echo "`date` INFO: Found tiller on server, using $(helm version --server --short)"
else
  tiller_already_deployed=
  # Need to init helm to deploy tiller
  if [[ $(kubectl version | grep Server | grep 'GitVersion:\"v1.6.') ]]; then
    # For kubernetes v6
    helm init
  else
    # For kubernetes >=v7
    kubectl create serviceaccount --namespace kube-system tiller
    # Requires account/service account to have add-iam-policy-binding to "roles/container.admin"
    kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    helm init --skip-refresh --upgrade --service-account tiller
  fi
fi

# Wait until helm tiller is up and ready to proceed
#  workaround until https://github.com/kubernetes/helm/issues/2114 resolved
if [[ -z "$tiller_already_deployed" ]] ; then
  kubectl rollout status -w deployment/tiller-deploy --namespace=kube-system
fi

echo "`date` INFO: READY TO DEPLOY Solace PubSub+ TO CLUSTER"
echo "#############################################################"
echo "Next steps to complete the deployment:"
if [[ "$(pwd)" != *solace-pks/solace ]]; then
  echo "cd solace  # replace with the path to your \"solace\" chart"
fi
echo "helm install . -f values.yaml"
echo "watch kubectl get pods --show-labels"

