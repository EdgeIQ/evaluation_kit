#!/usr/bin/env bash

set -eu

DIAGSLAVE_HOME='/opt/diagslave'

wget 'https://www.modbusdriver.com/downloads/diagslave.tgz'

mkdir -p "${DIAGSLAVE_HOME}/log"

tar xzf diagslave.tgz --directory '/opt'

rm diagslave.tgz

cat >/etc/systemd/system/diagslave.service <<EOF
[Unit]
Description=Diagslave service
Documentation=https://www.modbusdriver.com/diagslave.html
Wants=network-online.target
After=network.target network-online.target

[Service]
Type=simple
KillMode=process
Restart=always
ExecStart=${DIAGSLAVE_HOME}/linux_arm-eabihf/diagslave -m tcp
StandardOutput=journal
StandardError=inherit
KillMode=control-group

[Install]
WantedBy=multi-user.target
EOF

systemctl enable diagslave
systemctl start diagslave
