#!/bin/bash

# Check if the required environment variable is set
if [ -z "$SENTINEL_TOKEN" ]; then
  echo "Error: SENTINEL_TOKEN environment variable is not set."
  echo "Please set the SENTINEL_TOKEN environment variable and try again."
  exit 1
fi

# Detect package manager
detect_package_manager() {
  if command -v apt &> /dev/null; then
    echo "deb"
  elif command -v yum &> /dev/null; then
    echo "rpm"
  else
    echo "unknown"
  fi
}

# Detect architecture
detect_architecture() {
  arch=$(uname -m)
  if [[ "$arch" == "x86_64" ]]; then
    echo "x64"
  elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
    echo "arm64"
  else
    echo "unsupported"
  fi
}

package_manager=$(detect_package_manager)
architecture=$(detect_architecture)

if [ "$package_manager" == "unknown" ]; then
  echo "Error: Unsupported package manager detected. Only RPM and DEB are supported."
  exit 1
fi

if [ "$architecture" == "unsupported" ]; then
  echo "Error: Unsupported architecture detected. Only x64 and arm64 are supported."
  exit 1
fi

# Variables
rpm_x64_url="https://github.com/dhomane/s1-agent-installer/releases/download/latest/s1-agent-latest.rpm"
rpm_arm64_url="https://github.com/dhomane/s1-agent-installer/releases/download/latest/s1-agent-latest-arm64.rpm"
deb_x64_url="https://github.com/dhomane/s1-agent-installer/releases/download/latest/s1-agent-latest.deb"
deb_arm64_url="https://github.com/dhomane/s1-agent-installer/releases/download/latest/s1-agent-latest-arm64.deb"

installation_file="/tmp/s1-agent-latest.${package_manager}"

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
  echo "Downloading Sentinel installation file for $architecture architecture..."
  
  if [ "$package_manager" == "rpm" ]; then
    if [ "$architecture" == "x64" ]; then
      url="${rpm_x64_url}"
    else
      url="${rpm_arm64_url}"
    fi
  else # deb
    if [ "$architecture" == "x64" ]; then
      url="${deb_x64_url}"
    else
      url="${deb_arm64_url}"
    fi
  fi
  
  echo "Using package URL: $url"
  curl -L -o "$installation_file" "$url"
  
  if [ $? -ne 0 ]; then
    echo "Error: Failed to download the Sentinel installation file."
    exit 1
  fi

  echo "Installing Sentinel..."
  if [ "$package_manager" == "rpm" ]; then
    rpm -i --nodigest "$installation_file"
  else
    dpkg -i "$installation_file"
  fi

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
  fi
fi

install_sentinel
check_sentinel_status

if [[ -n "$agent_version" && -n "$uuid" ]]; then
  set_sentinel_facts
else
  log_failure
fi