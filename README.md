# EdgeIQ Evaluation Kit

This directory contains a few scripts that show how EdgeIQ can be configured to manage an edge gateway device with a connected Modbus sensor. The sensor data will be forwarded to an HTTP listener. The [`httpprint.py`](httpprint.py) is an example of such a listener that will print out all HTTP messages that it receives.

Included are two different ways to configure EdgeIQ to manage devices.

* Managed gateway device connected to Modbus sensor. Simplest configuration though you can not easily see the reporting status of each individual sensor.
  * [`create_device_raspberry_pi_linux_gateway.sh`](create_device_raspberry_pi_linux_gateway.sh)
* Managed gateway device AND managed sensor device as Modbus Sensor. Sensor devices are discreet managed entities that allow the operator to see its status and send commands in isolation of other sensors.
  * [`create_device_raspberry_pi_linux_gateway_sensor.sh`](create_device_raspberry_pi_linux_gateway_sensor.sh)

These scripts source in [`setenv.sh`](setenv.sh) to make it easier to set your environment variables once.

These scripts will create a `cleanup-poc-<timestamp>.sh` file that contains API commands to delete EdgeIQ artifacts created by the create script. The cleanup scripts will delete themselves upon successful completion.

> Warning: these test scripts do not currently protect against creating duplicate artifacts, nor do they detect if devices are present with the same target Unique ID. EdgeIQ will prevent you from creating duplicate devices with the same unique ID (which is good), however this may cause issues with the correct configuration by the scripts.

There is a helper script [`list_entities.sh`](list_entities.sh) that will display all the various EdgeIQ objects you have access to within your account.

Requirements to run these scripts:

* `curl` - tested against curl version 7.64.1
* `jq` - tested against version 1.6. Installation and documentation at <https://stedolan.github.io/jq>

These scripts were tested against the free [diagslave](https://www.modbusdriver.com/diagslave.html) Modbus simulator, e.g. `diagslave -m tcp`.

To use the included [`httpprint.py`](httpprint.py), you need to have a recent version of Python 3 installed. e.g. `python3 httpprint.py`

The Modbus sensor/simulator and the HTTP Listener should be running **BEFORE** running these scripts.

To install EdgeIQ local service on a Raspberry Pi 3 or 4 running Linux, execute the following command

```bash
wget --quiet --output-document='install.sh' \
  'https://machineshopapi.com/api/v1/platform/installers/install.sh' \
  && sudo /bin/bash install.sh --company '<your EdgeIQ account ID>' \
  --make 'rpf' --model 'rpi' \
  --url 'https://machineshopapi.com/api/v1/platform/installers/rpf/rpi/edge-2.6.1.run'
```

The EdgeIQ local service is installed as a `systemd` managed service called `edge.service` so for example you can stop it using this command, `sudo systemctl stop edge`. The EdgeIQ local service is installed into `/opt/edge` and log files are located in a day time stamped file, e.g. `/opt/edge/log/edge.log.2020-05-18`.
