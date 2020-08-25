#!/usr/bin/env bash

set -eu

# URL for EdgeIQ API server; you should not change
export BASE_URL='https://api.edgeiq.io/api/v1/platform'

# Your EdgeIQ credentials
export ADMIN_EMAIL=${ADMIN_EMAIL:-'<your EdgeIQ username>'}
export ADMIN_PASSWORD=${ADMIN_PASSWORD:-'<your EdgeIQ password>'}

export GATEWAY_USERNAME=${GATEWAY_USERNAME:-'<username for Gateway>'}

# EdgeIQ local service uses MAC address of first ethernet interface reported by `ifconfig`
export GATEWAY_UNIQUE_ID=${GATEWAY_UNIQUE_ID:-'<Unique id for Gateway>'}

# IP Address of Gateway device
export GATEWAY_IP=${GATEWAY_IP:-'<Gateway device IP>'}

# Gateway's EdgeIQ device type
# * Raspberry PI - 'rpf'
# * x86_64 - 'generic'
export GATEWAY_MANUFACTURER='rpf'

# Gateway's EdgeIQ device type
# * Raspberry PI linux - 'rpi'
# * x86_64 Linux - 'linux'
export GATEWAY_MODEL='rpi'

# EdgeIQ SmartEdge version
export SMARTEDGE_VERSION='2.6.5'
