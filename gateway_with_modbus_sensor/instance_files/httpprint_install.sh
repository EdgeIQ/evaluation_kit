#!/usr/bin/env bash

set -eu

SERVICE_HOME='/home/ubuntu'

PYTHON3=$(which python3)

pip3 install requests
pip3 install getmac

service_name='httpprint'

systemctl disable --now "${service_name}" > /dev/null 2>&1 || true # ignore errors

cat >"/etc/systemd/system/${service_name}.service" <<EOF
[Unit]
Description=HTTP Push Sensor
Wants=network-online.target edge.service
After=network.target network-online.target edge.service

[Service]
Type=simple
Environment=PYTHONUNBUFFERED=1
ExecStart=${PYTHON3} ${SERVICE_HOME}/httpprint.py
Restart=on-failure
KillMode=control-group

[Install]
WantedBy=multi-user.target
EOF

chmod 664 "/etc/systemd/system/${service_name}.service"

systemctl enable --now "${service_name}"
