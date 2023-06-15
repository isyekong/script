#!/bin/bash

# Check if curl is installed
if ! command -v curl >/dev/null 2>&1; then
  echo "curl is not installed. Updating apt and installing curl..."
  apt update
  apt install -y curl
fi

# Create download directory if it doesn't exist
mkdir -p /var/tmp/bird

# Function to download file with retry
download_file() {
  local url=$1
  local destination=$2
  local retry_count=3
  local retry_delay=3

  while [ $retry_count -gt 0 ]; do
    echo "Downloading $url..."
    if curl -sSL -o "$destination" "$url"; then
      echo "Download complete."
      return 0
    else
      echo "Download failed. Retrying in $retry_delay seconds..."
      sleep $retry_delay
      retry_count=$((retry_count - 1))
    fi
  done

  echo "Unable to download $url after multiple retries."
  return 1
}

# Check if /etc/bird/vars.conf exists
if [ -f "/etc/bird/vars.conf" ]; then
  # Check the value of MY_COUNTRY in /etc/bird/vars.conf
  if grep -q "MY_COUNTRY\s*=\s*156" "/etc/bird/vars.conf"; then
    echo "China mainland node detected. Downloading with proxy..."

    # Downloading files from Group A with proxy
    echo "Downloading files from Group A with proxy..."
    download_file "https://proxy.moeqing.com/https://raw.githubusercontent.com/MoeQing-Network/MoeQing-Network-BIRD2-Config/beta/node/bird.conf" "/var/tmp/bird/bird.conf" &&
    download_file "https://proxy.moeqing.com/https://raw.githubusercontent.com/MoeQing-Network/MoeQing-Network-BIRD2-Config/beta/node/version.txt" "/var/tmp/bird/version.txt"
  else
    echo "Non-China mainland node detected. Downloading without proxy..."

    # Downloading files from Group A without proxy
    echo "Downloading files from Group A without proxy..."
    download_file "https://raw.githubusercontent.com/MoeQing-Network/MoeQing-Network-BIRD2-Config/beta/node/bird.conf" "/var/tmp/bird/bird.conf" &&
    download_file "https://raw.githubusercontent.com/MoeQing-Network/MoeQing-Network-BIRD2-Config/beta/node/version.txt" "/var/tmp/bird/version.txt"
  fi
else
  echo "/etc/bird/vars.conf file not found. Skipping download from Group A."
fi

# Downloading files from Group B
echo "Downloading files from Group B..."
download_file "https://raw.githubusercontent.com/MoeQing-Network/MoeQing-Network-BIRD2-Config/beta/node/functions/aws_prefix.conf" "/var/tmp/bird/aws_prefix.conf" &&
download_file "https://raw.githubusercontent.com/MoeQing-Network/MoeQing-Network-BIRD2-Config/beta/node/functions/cloudflare_prefix.conf" "/var/tmp/bird/cloudflare_prefix.conf" &&
download_file "https://raw.githubusercontent.com/MoeQing-Network/MoeQing-Network-BIRD2-Config/beta/node/functions/cn_prefix.conf" "/var/tmp/bird/cn_prefix.conf" &&
download_file "https://raw.githubusercontent.com/MoeQing-Network/MoeQing-Network-BIRD2-Config/beta/node/functions/neighbor.conf" "/var/tmp/bird/neighbor.conf" &&
download_file "https://raw.githubusercontent.com/MoeQing-Network/MoeQing-Network-BIRD2-Config/beta/node/functions/predefined.conf" "/var/tmp/bird/predefined.conf"

# Moving Group A files to /etc/bird
if [ -f "/etc/bird/vars.conf" ]; then
  if grep -q "MY_COUNTRY\s*=\s*156" "/etc/bird/vars.conf"; then
    echo "Moving Group A files to /etc/bird with proxy..."
    cp /var/tmp/bird/bird.conf /etc/bird/ &&
    cp /var/tmp/bird/version.txt /etc/bird/
  else
    echo "Moving Group A files to /etc/bird without proxy..."
    cp /var/tmp/bird/bird.conf /etc/bird/ &&
    cp /var/tmp/bird/version.txt /etc/bird/
  fi
fi

# Moving Group B files to /etc/bird/functions
echo "Moving Group B files to /etc/bird/functions..."
cp /var/tmp/bird/aws_prefix.conf /etc/bird/functions/ &&
cp /var/tmp/bird/cloudflare_prefix.conf /etc/bird/functions/ &&
cp /var/tmp/bird/cn_prefix.conf /etc/bird/functions/ &&
cp /var/tmp/bird/neighbor.conf /etc/bird/functions/ &&
cp /var/tmp/bird/predefined.conf /etc/bird/functions/

# Running birdc configure
echo "Running birdc configure..."
birdc configure

# Clearing the download directory
echo "Clearing download directory..."
rm -rf /var/tmp/bird/*
