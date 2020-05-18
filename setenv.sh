#!/usr/bin/env bash

set -eu

# URL for EdgeIQ API server; you should not change
export BASE_URL='https://machineshopapi.com/api/v1/platform'

# Your EdgeIQ credentials
export ADMIN_EMAIL=${ADMIN_EMAIL:-'<your EdgeIQ username>'}
export ADMIN_PASSWORD=${ADMIN_PASSWORD:-'<your EdgeIQ password>'}

# EdgeIQ local service uses MAC address of first ethernet interface reported by `ifconfig`
export GATEWAY_UNIQUE_ID=${GATEWAY_UNIQUE_ID:-'<Unique id for Gateway>'}

# Account unique id for Modbus Sensor
SENSOR_UNIQUE_ID=${SENSOR_UNIQUE_ID:-"$(whoami)-1234"}
export SENSOR_UNIQUE_ID

# IP Address of Modbus TCP sensor/simulator
export MODBUS_SENSOR_IP=${MODBUS_SENSOR_IP:-'<IP address for Modbus sensor>'}

# Port numberr for Modbus TCP sensor/simulator
export MODBUS_SENSOR_PORT=${MODBUS_SENSOR_PORT:-502}

# This script configures EdgeIQ local service to forward Modbus reports as HTTP PUT messages to the following URL
export HTTP_LISTENER_URL=${HTTP_LISTENER_URL:-"http://$MODBUS_SENSOR_IP:5005"}
