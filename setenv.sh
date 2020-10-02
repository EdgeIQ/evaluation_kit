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

# EdgeIQ SmartEdge version
export SMARTEDGE_VERSION='2.6.6'

# Gateway's EdgeIQ device type
# * Raspberry PI - 'rpf'
# * x86_64 - 'generic'
export GATEWAY_MANUFACTURER='rpf'
# export GATEWAY_MANUFACTURER='generic'

# Gateway's EdgeIQ device type
# * Raspberry PI linux - 'rpi'
# * x86_64 Linux - 'linux'
export GATEWAY_MODEL='rpi'
# export GATEWAY_MODEL='linux'

# EdgeIQ / AWS Integration
# see also: https://dev.edgeiq.io/docs/aws-iot

export AWS_IOT_GG_URL=${AWS_IOT_GG_URL:-'https://d1onfpft10uf5o.cloudfront.net/greengrass-core/downloads/1.10.2/greengrass-linux-armv7l-1.10.2.tar.gz'}
# export AWS_IOT_GG_URL=${AWS_IOT_GG_URL:-'https://d1onfpft10uf5o.cloudfront.net/greengrass-core/downloads/1.10.2/greengrass-linux-x86-64-1.10.2.tar.gz'}

export AWS_IOT_REGION=${AWS_IOT_REGION:-'us-east-2'}
export AWS_IOT_EXTERNAL_ID=${AWS_IOT_EXTERNAL_ID:-'<AWS external id>'}
export AWS_IOT_ROLE_ARN=${AWS_IOT_ROLE_ARN:-'<AWS role arn>'}

# EdgeIQ Escrow token
# This can be any random string, unique to your account.
export ESCROW_TOKEN=${ESCROW_TOKEN:-'EVALKIT918374698173649523'}
