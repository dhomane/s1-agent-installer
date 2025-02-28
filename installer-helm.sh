#!/bin/bash

# Check if SITE_KEY environment variable is set
if [ -z "$SITE_KEY" ]; then
  echo "Error: SITE_KEY environment variable is not set."
  exit 1
fi

# Get the current context
CURRENT_CONTEXT=$(kubectl config current-context)

# If no context is set, exit with an error
if [ -z "$CURRENT_CONTEXT" ]; then
  echo "Error: No current Kubernetes context set. Please set the context first."
  exit 1
fi

# Extract the unique cluster ID from the current context (match `mstr-cluster-<unique-id>`)
CLUSTER_ID=$(echo "$CURRENT_CONTEXT" | awk -F'mstr-cluster-' '{print "cluster-" $2}' | cut -d'-' -f1,2)

# If unable to extract cluster ID, exit with an error
if [ -z "$CLUSTER_ID" ]; then
  echo "Error: Unable to extract cluster ID from the context: $CURRENT_CONTEXT, setting it same as context"
  CLUSTER_ID="$CURRENT_CONTEXT"
fi

# Use the cluster ID to construct the required format
FINAL_CLUSTER_NAME="cluster-$CLUSTER_ID"

echo "Setting kubeconfig context for: $CURRENT_CONTEXT (extracted cluster: $FINAL_CLUSTER_NAME)"

# Set the kubeconfig context
kubectl config use-context "$CURRENT_CONTEXT" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to set kubeconfig context for: $CURRENT_CONTEXT"
    exit 1
fi

# Add the SentinelOne Helm repository
helm repo add sentinelone https://charts.sentinelone.com

echo "Installing SentinelOne agent for cluster: $FINAL_CLUSTER_NAME"

# Check if the release already exists and either install or upgrade accordingly
if helm status sentinelone --namespace=sentinelone > /dev/null 2>&1; then
    helm upgrade sentinelone --namespace=sentinelone \
    --version 23.4.2 \
    --set secrets.site_key.value="$SITE_KEY" \
    --set configuration.repositories.agent="dhomane/s1agent" \
    --set configuration.tag.agent="23.4.2-x86_64" \
    --set configuration.repositories.helper="dhomane/s1helper" \
    --set configuration.tag.helper="23.4.2-x86_64" \
    --set configuration.cluster.name="$FINAL_CLUSTER_NAME" \
    sentinelone/s1-agent
else
    helm install sentinelone --namespace=sentinelone --create-namespace \
    --version 23.4.2 \
    --set secrets.site_key.value="$SITE_KEY" \
    --set configuration.repositories.agent="dhomane/s1agent" \
    --set configuration.tag.agent="23.4.2-x86_64" \
    --set configuration.repositories.helper="dhomane/s1helper" \
    --set configuration.tag.helper="23.4.2-x86_64" \
    --set configuration.cluster.name="$FINAL_CLUSTER_NAME" \
    sentinelone/s1-agent
fi

echo "Installation completed for: $FINAL_CLUSTER_NAME"
