#!/usr/bin/env bash

set -eu

DIAGSLAVE_HOME='/opt/diagslave'

mkdir -p "${DIAGSLAVE_HOME}"

cd "${DIAGSLAVE_HOME}"

wget 'https://www.modbusdriver.com/downloads/diagslave.tgz'

tar xzf diagslave.tgz

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
# StandardOutput=journal+console
# StandardError=journal+console
KillMode=control-group

[Install]
WantedBy=multi-user.target
EOF

chmod 664 /etc/systemd/system/diagslave.service

systemctl enable diagslave
systemctl start diagslave
