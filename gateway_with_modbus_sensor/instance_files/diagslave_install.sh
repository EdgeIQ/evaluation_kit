#!/usr/bin/env bash

set -eu

DIAGSLAVE_HOME='/opt/diagslave'

DIAGSLAVE_ARCH='linux_arm-eabihf'
case "$(uname --hardware-platform)" in
  'x86_64')
    DIAGSLAVE_ARCH='linux_x86-64'
    ;;
esac

mkdir -p "${DIAGSLAVE_HOME}"

cd "${DIAGSLAVE_HOME}"

wget 'https://www.modbusdriver.com/downloads/diagslave.tgz'

tar xzf diagslave.tgz

rm diagslave.tgz

service_name='diagslave'

systemctl disable --now "${service_name}" > /dev/null 2>&1 || true # ignore errors

cat >"/etc/systemd/system/${service_name}.service" <<EOF
[Unit]
Description=Diagslave service
Documentation=https://www.modbusdriver.com/diagslave.html
Wants=network-online.target
After=network.target network-online.target

[Service]
Type=simple
ExecStart=${DIAGSLAVE_HOME}/diagslave/${DIAGSLAVE_ARCH}/diagslave -m tcp
Restart=on-failure
KillMode=control-group

[Install]
WantedBy=multi-user.target
EOF

chmod 664 "/etc/systemd/system/${service_name}.service"

systemctl enable --now "${service_name}"
