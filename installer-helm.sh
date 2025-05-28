#!/bin/bash

# Check if SITE_KEY is passed in the environment
if [[ -z "$SITE_KEY" ]]; then
    echo "❌ ERROR: SITE_KEY environment variable is not set."
    echo "💡 Set it using: export SITE_KEY='<your-base64-site-key>'"
    exit 1
fi

# Add the SentinelOne Helm repository (if not already added)
helm repo add sentinelone https://charts.sentinelone.com 2>/dev/null || true

# Get the current kubeconfig context
CURRENT_CONTEXT=$(kubectl config current-context)

# Use the current context
kubectl config use-context "$CURRENT_CONTEXT"

echo "🚀 Installing SentinelOne agent on: $CURRENT_CONTEXT"

CLUSTER_NAME="$CURRENT_CONTEXT"

# Install or upgrade
if helm status sentinelone --namespace=sentinelone > /dev/null 2>&1; then
    echo "🔄 Upgrading SentinelOne agent..."
    helm upgrade sentinelone --namespace=sentinelone \
        --version 24.2.2 \
        --set secrets.site_key.value="$SITE_KEY" \
        --set configuration.repositories.agent="dhomane/s1agent" \
        --set configuration.tag.agent="24.2.2-x86_64" \
        --set configuration.repositories.helper="dhomane/s1helper" \
        --set configuration.tag.helper="24.2.2-x86_64" \
        --set configuration.cluster.name="$CLUSTER_NAME" \
        sentinelone/s1-agent
else
    echo "📦 Installing SentinelOne agent..."
    helm install sentinelone --namespace=sentinelone --create-namespace \
        --version 24.2.2 \
        --set secrets.site_key.value="$SITE_KEY" \
        --set configuration.repositories.agent="dhomane/s1agent" \
        --set configuration.tag.agent="24.2.2-x86_64" \
        --set configuration.repositories.helper="dhomane/s1helper" \
        --set configuration.tag.helper="24.2.2-x86_64" \
        --set configuration.cluster.name="$CLUSTER_NAME" \
        sentinelone/s1-agent
fi

echo "✅ Done: SentinelOne agent deployed on $CURRENT_CONTEXT"
