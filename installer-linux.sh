#!/bin/bash

# Check if the required environment variable is set
if [ -z "$SENTINEL_TOKEN" ]; then
  echo "Error: SENTINEL_TOKEN environment variable is not set."
  echo "Please set the SENTINEL_TOKEN environment variable and try again."
  exit 1
fi

# Variables
installation_url="https://github.com/dhomane/s1-agent-installer/releases/download/latest/s1-agent-latest.rpm"
installation_file="/tmp/s1-agent-latest.rpm"

# Functions
check_sentinel_status() {
  agent_version=$(/opt/sentinelone/bin/sentinelctl version | grep 'Agent version' | awk -F ':' '{print $2}' | tr -d ' ')
  uuid=$(/opt/sentinelone/bin/sentinelctl management uuid get | awk -F ':' '{print $2}' | tr -d ' ')
}

set_sentinel_facts() {
  echo "Sentinel Agent Version: $agent_version"
  echo "Sentinel UUID: $uuid"
}


install_sentinel() {
  echo "Downloading Sentinel installation file..."
  curl -L -o "$installation_file" "$installation_url"
  
  if [ $? -ne 0 ]; then
    echo "Error: Failed to download the Sentinel installation file."
    exit 1
  fi

  echo "Installing Sentinel..."
  rpm -i --nodigest "$installation_file"

  # Register the token
  /opt/sentinelone/bin/sentinelctl management token set "$SENTINEL_TOKEN"

  # Start Sentinel process
  /opt/sentinelone/bin/sentinelctl control start
}

log_failure() {
  echo "Sentinel installation failed. Setting failure facts..."
  agent_version="cannot_install_sentinel"
  uuid="cannot_install_sentinel"
  set_sentinel_facts
}

# Main logic
check_sentinel_status

if [[ -n "$agent_version" && -n "$uuid" ]]; then
  set_sentinel_facts
  exit 0
fi

if [[ -z "$uuid" && -z "$agent_version" ]]; then
  /opt/sentinelone/bin/sentinelctl control start
  check_sentinel_status

  if [[ -n "$agent_version" && -n "$uuid" ]]; then
    set_sentinel_facts
    exit 0
  else
    uninstall_sentinel
  fi
fi

install_sentinel
check_sentinel_status

if [[ -n "$agent_version" && -n "$uuid" ]]; then
  set_sentinel_facts
else
  log_failure
fi
