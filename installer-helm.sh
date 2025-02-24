#!/bin/bash

# Check if SITE_KEY environment variable is set
if [ -z "$SITE_KEY" ]; then
  echo "Error: SITE_KEY environment variable is not set."
  exit 1
fi

# List of contexts that match the selected clusters (using current context)
CONTEXT_NAMES=($(kubectl config get-contexts -o name))

# If no contexts are found, exit with an error
if [ ${#CONTEXT_NAMES[@]} -eq 0 ]; then
  echo "Error: No Kubernetes contexts found. Please check your kubectl configuration."
  exit 1
fi

# Add the SentinelOne Helm repository
helm repo add sentinelone https://charts.sentinelone.com

# Function to install SentinelOne agent for a given context
install_agent() {
    local CONTEXT_NAME=$1
    # Extract the cluster name from the context (match `mstr-cluster-<unique-id>-<suffix>`)
    local CLUSTER_NAME=$(echo "$CONTEXT_NAME" | grep -oP 'mstr-cluster-[^-]+-[^-]+')

    if [ -z "$CLUSTER_NAME" ]; then
        echo "Warning: Unable to extract cluster name from context: $CONTEXT_NAME"
        return
    fi

    echo "Setting kubeconfig context for: $CONTEXT_NAME (extracted cluster: $CLUSTER_NAME)"

    # Set the kubeconfig context
    kubectl config use-context "$CONTEXT_NAME" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Error: Failed to set kubeconfig context for: $CONTEXT_NAME"
        return
    fi

    echo "Installing SentinelOne agent for cluster: $CLUSTER_NAME"

    # Check if the release already exists and either install or upgrade accordingly
    if helm status sentinelone --namespace=sentinelone > /dev/null 2>&1; then
        helm upgrade sentinelone --namespace=sentinelone \
        --version 23.4.2 \
        --set secrets.site_key.value="$SITE_KEY" \
        --set configuration.repositories.agent="dhomane/s1agent" \
        --set configuration.tag.agent="23.4.2-x86_64" \
        --set configuration.repositories.helper="dhomane/s1helper" \
        --set configuration.tag.helper="23.4.2-x86_64" \
        --set configuration.cluster.name="$CLUSTER_NAME" \
        sentinelone/s1-agent
    else
        helm install sentinelone --namespace=sentinelone --create-namespace \
        --version 23.4.2 \
        --set secrets.site_key.value="$SITE_KEY" \
        --set configuration.repositories.agent="dhomane/s1agent" \
        --set configuration.tag.agent="23.4.2-x86_64" \
        --set configuration.repositories.helper="dhomane/s1helper" \
        --set configuration.tag.helper="23.4.2-x86_64" \
        --set configuration.cluster.name="$CLUSTER_NAME" \
        sentinelone/s1-agent
    fi

    echo "Installation completed for: $CLUSTER_NAME"
}

# Loop through all contexts and start the installation sequentially
for CONTEXT_NAME in "${CONTEXT_NAMES[@]}"; do
    install_agent "$CONTEXT_NAME"
done

echo "All installations completed."
