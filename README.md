
# EdgeIQ Evaluation Kit

## Requirements to run these scripts
These scripts assume that you are working with the following test environment:

`host` - PC, Macbook, VM, etc. - used to run scripts and SSH to gateway
`gateway` - Embedded x86 or ARM device, Raspberry Pi 3/4, AWS VM, etc.
`sensors` - sensor devices can be a target to ping, temperature sensor, etc.

![enter image description here](https://mermaid.ink/img/eyJjb2RlIjoiZ3JhcGggUkxcblxuICBzdWJncmFwaCBMQU5cbiAgICBDKFtHYXRld2F5XSkgLS0tIHxtb2RidXN8IEooW3NlbnNvciAxXSlcbiAgICBDKFtHYXRld2F5XSkgLS4tIHxzbm1wfCBLKFtzZW5zb3IgMl0pXG4gICAgQyhbR2F0ZXdheV0pIC0uLSB8aHR0cHwgTChbc2Vuc29yIDNdKVxuICBlbmRcbiAgICBzdWJncmFwaCBJbnRlcm5ldFxuICAgICAgQVsoRWRnZUlRIEFQSSldID09PSBDKFtHYXRld2F5XSlcbiAgICBlbmRcbiAgICBzdWJncmFwaCBob3N0W01hY2Jvb2tdXG4gICAgICBFW2hvc3RdIC0uLT4gfGh0dHBzL2N1cmx8IEFbKEVkZ2VJUSBBUEkpXVxuICAgICAgRVtob3N0XSAtLi0gfHNzaHwgQyhbR2F0ZXdheV0pXG4gICAgZW5kIiwibWVybWFpZCI6eyJ0aGVtZSI6ImRlZmF1bHQiLCJ0aGVtZVZhcmlhYmxlcyI6eyJiYWNrZ3JvdW5kIjoid2hpdGUiLCJwcmltYXJ5Q29sb3IiOiIjRUNFQ0ZGIiwic2Vjb25kYXJ5Q29sb3IiOiIjZmZmZmRlIiwidGVydGlhcnlDb2xvciI6ImhzbCg4MCwgMTAwJSwgOTYuMjc0NTA5ODAzOSUpIiwicHJpbWFyeUJvcmRlckNvbG9yIjoiaHNsKDI0MCwgNjAlLCA4Ni4yNzQ1MDk4MDM5JSkiLCJzZWNvbmRhcnlCb3JkZXJDb2xvciI6ImhzbCg2MCwgNjAlLCA4My41Mjk0MTE3NjQ3JSkiLCJ0ZXJ0aWFyeUJvcmRlckNvbG9yIjoiaHNsKDgwLCA2MCUsIDg2LjI3NDUwOTgwMzklKSIsInByaW1hcnlUZXh0Q29sb3IiOiIjMTMxMzAwIiwic2Vjb25kYXJ5VGV4dENvbG9yIjoiIzAwMDAyMSIsInRlcnRpYXJ5VGV4dENvbG9yIjoicmdiKDkuNTAwMDAwMDAwMSwgOS41MDAwMDAwMDAxLCA5LjUwMDAwMDAwMDEpIiwibGluZUNvbG9yIjoiIzMzMzMzMyIsInRleHRDb2xvciI6IiMzMzMiLCJtYWluQmtnIjoiI0VDRUNGRiIsInNlY29uZEJrZyI6IiNmZmZmZGUiLCJib3JkZXIxIjoiIzkzNzBEQiIsImJvcmRlcjIiOiIjYWFhYTMzIiwiYXJyb3doZWFkQ29sb3IiOiIjMzMzMzMzIiwiZm9udEZhbWlseSI6IlwidHJlYnVjaGV0IG1zXCIsIHZlcmRhbmEsIGFyaWFsIiwiZm9udFNpemUiOiIxNnB4IiwibGFiZWxCYWNrZ3JvdW5kIjoiI2U4ZThlOCIsIm5vZGVCa2ciOiIjRUNFQ0ZGIiwibm9kZUJvcmRlciI6IiM5MzcwREIiLCJjbHVzdGVyQmtnIjoiI2ZmZmZkZSIsImNsdXN0ZXJCb3JkZXIiOiIjYWFhYTMzIiwiZGVmYXVsdExpbmtDb2xvciI6IiMzMzMzMzMiLCJ0aXRsZUNvbG9yIjoiIzMzMyIsImVkZ2VMYWJlbEJhY2tncm91bmQiOiIjZThlOGU4IiwiYWN0b3JCb3JkZXIiOiJoc2woMjU5LjYyNjE2ODIyNDMsIDU5Ljc3NjUzNjMxMjglLCA4Ny45MDE5NjA3ODQzJSkiLCJhY3RvckJrZyI6IiNFQ0VDRkYiLCJhY3RvclRleHRDb2xvciI6ImJsYWNrIiwiYWN0b3JMaW5lQ29sb3IiOiJncmV5Iiwic2lnbmFsQ29sb3IiOiIjMzMzIiwic2lnbmFsVGV4dENvbG9yIjoiIzMzMyIsImxhYmVsQm94QmtnQ29sb3IiOiIjRUNFQ0ZGIiwibGFiZWxCb3hCb3JkZXJDb2xvciI6ImhzbCgyNTkuNjI2MTY4MjI0MywgNTkuNzc2NTM2MzEyOCUsIDg3LjkwMTk2MDc4NDMlKSIsImxhYmVsVGV4dENvbG9yIjoiYmxhY2siLCJsb29wVGV4dENvbG9yIjoiYmxhY2siLCJub3RlQm9yZGVyQ29sb3IiOiIjYWFhYTMzIiwibm90ZUJrZ0NvbG9yIjoiI2ZmZjVhZCIsIm5vdGVUZXh0Q29sb3IiOiJibGFjayIsImFjdGl2YXRpb25Cb3JkZXJDb2xvciI6IiM2NjYiLCJhY3RpdmF0aW9uQmtnQ29sb3IiOiIjZjRmNGY0Iiwic2VxdWVuY2VOdW1iZXJDb2xvciI6IndoaXRlIiwic2VjdGlvbkJrZ0NvbG9yIjoicmdiYSgxMDIsIDEwMiwgMjU1LCAwLjQ5KSIsImFsdFNlY3Rpb25Ca2dDb2xvciI6IndoaXRlIiwic2VjdGlvbkJrZ0NvbG9yMiI6IiNmZmY0MDAiLCJ0YXNrQm9yZGVyQ29sb3IiOiIjNTM0ZmJjIiwidGFza0JrZ0NvbG9yIjoiIzhhOTBkZCIsInRhc2tUZXh0TGlnaHRDb2xvciI6IndoaXRlIiwidGFza1RleHRDb2xvciI6IndoaXRlIiwidGFza1RleHREYXJrQ29sb3IiOiJibGFjayIsInRhc2tUZXh0T3V0c2lkZUNvbG9yIjoiYmxhY2siLCJ0YXNrVGV4dENsaWNrYWJsZUNvbG9yIjoiIzAwMzE2MyIsImFjdGl2ZVRhc2tCb3JkZXJDb2xvciI6IiM1MzRmYmMiLCJhY3RpdmVUYXNrQmtnQ29sb3IiOiIjYmZjN2ZmIiwiZ3JpZENvbG9yIjoibGlnaHRncmV5IiwiZG9uZVRhc2tCa2dDb2xvciI6ImxpZ2h0Z3JleSIsImRvbmVUYXNrQm9yZGVyQ29sb3IiOiJncmV5IiwiY3JpdEJvcmRlckNvbG9yIjoiI2ZmODg4OCIsImNyaXRCa2dDb2xvciI6InJlZCIsInRvZGF5TGluZUNvbG9yIjoicmVkIiwibGFiZWxDb2xvciI6ImJsYWNrIiwiZXJyb3JCa2dDb2xvciI6IiM1NTIyMjIiLCJlcnJvclRleHRDb2xvciI6IiM1NTIyMjIiLCJjbGFzc1RleHQiOiIjMTMxMzAwIiwiZmlsbFR5cGUwIjoiI0VDRUNGRiIsImZpbGxUeXBlMSI6IiNmZmZmZGUiLCJmaWxsVHlwZTIiOiJoc2woMzA0LCAxMDAlLCA5Ni4yNzQ1MDk4MDM5JSkiLCJmaWxsVHlwZTMiOiJoc2woMTI0LCAxMDAlLCA5My41Mjk0MTE3NjQ3JSkiLCJmaWxsVHlwZTQiOiJoc2woMTc2LCAxMDAlLCA5Ni4yNzQ1MDk4MDM5JSkiLCJmaWxsVHlwZTUiOiJoc2woLTQsIDEwMCUsIDkzLjUyOTQxMTc2NDclKSIsImZpbGxUeXBlNiI6ImhzbCg4LCAxMDAlLCA5Ni4yNzQ1MDk4MDM5JSkiLCJmaWxsVHlwZTciOiJoc2woMTg4LCAxMDAlLCA5My41Mjk0MTE3NjQ3JSkifX0sInVwZGF0ZUVkaXRvciI6ZmFsc2V9)

from a development host, and will be using SSH to install the edge software on your gateway device.

* `bash` - version 4.x or newer
* `curl` - tested against curl version 7.64.1
* `jq` - tested against version 1.6. See: <https://stedolan.github.io/jq>

Test environment:

## Setup

Update the [`setenv.sh`](setenv.sh) file with your

* EdgeIQ username and password
* SSH username for your gateway device
* Your gateway device MAC address and associated IP address
* Configure EdgeIQ Device Type - defaults to Raspberry Pi 3/4 running recent Debian/Ubuntu linux

## Examples

* EdgeIQ Portal: <https://app.edgeiq.io>
* EdgeIQ API Base URL: <https://api.edgeiq.io/api/v1/platform>
* EdgeIQ Documentation: <https://dev.edgeiq.io/>

The EdgeIQ local service is installed as a `systemd` managed service called `edge.service` so for example you can stop it using this command, `sudo systemctl stop edge`. The EdgeIQ local service is installed into `/opt/edge` and log files are located in a day time stamped file, e.g. `/opt/edge/log/edge.log.2020-05-18`.

> Warning: these test scripts do not currently protect against creating duplicate artifacts, nor do they detect if devices are present with the same target Unique ID. EdgeIQ will prevent you from creating duplicate devices with the same unique ID (which is good), however this may cause issues with the correct configuration by the scripts.

Note: you will need to run the `cleanup-demo-<timestamp>.sh` script between running each example as only one EdgeIQ Device can exist against a single `Unique_Id`.

### Simple Gateway example

In `simple_gateway` subdirectory, run the following commands.

1. Run [`create_edgeiq_configuration.sh`](simple_gateway/create_edgeiq_configuration.sh). This will configure an EdgeIQ Device that can be used to remotely manage your gateway
2. Run [`gateway_provision.sh`](simple_gateway/gateway_provision.sh). This will install the EdgeIQ SmartEdge software onto the gateway and associate it with the EdgeIQ Device configured in the previous step.

The `create_edgeiq_configuration.sh` script will create a `cleanup-demo-<timestamp>.sh` file that contains API commands to delete EdgeIQ artifacts created by the create script. The cleanup scripts will delete themselves upon successful completion.

There is a helper script [`query_entities.sh`](simple_gateway/query_entities.sh) that provides examples of various ways to query artifacts from EdgeIQ.

### Gateway with ModBus Sensor Device

This example shows how EdgeIQ can be configured to manage an edge gateway device with a connected Modbus sensor. The sensor data will be forwarded to an HTTP listener. The [`httpprint.py`](gateway_with_modbus_sensor/instance_files/httpprint.py) is an example of such a listener that will print out all HTTP messages that it receives.

Notes:

* These scripts were tested against the free [diagslave](https://www.modbusdriver.com/diagslave.html) Modbus simulator, e.g. `diagslave -m tcp`.
* To use the included [`httpprint.py`](gateway_with_modbus_sensor/instance_files/httpprint.py), you need to have a recent version of Python 3 installed. e.g. `python3 httpprint.py`
* To see the `httpprint.py` output, run on the gateway device, e.g. Raspberry Pi, the following command `journalctl -f -all -u httpprint`.

In `gateway_with_modbus_sensor` subdirectory, run the following commands.

1. Run [`create_edgeiq_configuration.sh`](gateway_with_modbus_sensor/create_edgeiq_configuration.sh). This will configure an EdgeIQ Device that can be used to remotely manage your gateway
2. Run [`gateway_provision.sh`](gateway_with_modbus_sensor/gateway_provision.sh). This will install the EdgeIQ SmartEdge software onto the gateway and associate it with the EdgeIQ Device configured in the previous step.

The `create_edgeiq_configuration.sh` script will create a `cleanup-demo-<timestamp>.sh` file that contains API commands to delete EdgeIQ artifacts created by the create script. The cleanup scripts will delete themselves upon successful completion.

There are some helper scripts:

* [`query_entities.sh`](gateway_with_modbus_sensor/query_entities.sh) provides examples of querying EdgeIQ for specific devices based on `unique_id` and that have a `demo` tag. More details on Query parameters [here](https://dev.edgeiq.io/docs/api-overrview#query-string-operators)
* [`diagslave_install.sh`](gateway_with_modbus_sensor/instance_files/diagslave_install.sh) is an example of how to install diagslave Modbus simulator as a systemd service. Must be run as root, e.g., `sudo ./diagslave_install.sh`. You can then use `journalctl -f --all -u diagslave` to follow logs. Note the `--all` options overcomes the `[xxB blob data]` by converting the binary output from diagslave.

The Modbus sensor/simulator and the HTTP Listener should be running **BEFORE** running these scripts.

### Gateway with Attached ModBus Sensor Device

This example shows how EdgeIQ can be configured to manage an edge gateway device with a connected Modbus sensor. The ModBus sensor is modeled as an attached device to the Gateway device. Otherwise this example is identical to Gateway with ModBus Sensor example. The sensor data will be forwarded to an HTTP listener. The [`httpprint.py`](gateway_with_attached_sensor/instance_files/httpprint.py) is an example of such a listener that will print out all HTTP messages that it receives.

Notes:

* These scripts were tested against the free [diagslave](https://www.modbusdriver.com/diagslave.html) Modbus simulator, e.g. `diagslave -m tcp`.
* To use the included [`httpprint.py`](gateway_with_attached_sensor/instance_files/httpprint.py), you need to have a recent version of Python 3 installed. e.g. `python3 httpprint.py`
* To see the `httpprint.py` output, run on the gateway device, e.g. Raspberry Pi, the following command `journalctl -f -all -u httpprint`.

In `gateway_with_attached_sensor` subdirectory, run the following commands.

1. Run [`create_edgeiq_configuration.sh`](gateway_with_attached_sensor/create_edgeiq_configuration.sh). This will configure an EdgeIQ Device that can be used to remotely manage your gateway
2. Run [`gateway_provision.sh`](gateway_with_attached_sensor/gateway_provision.sh). This will install the EdgeIQ SmartEdge software onto the gateway and associate it with the EdgeIQ Device configured in the previous step.

The `create_edgeiq_configuration.sh` script will create a `cleanup-demo-<timestamp>.sh` file that contains API commands to delete EdgeIQ artifacts created by the create script. The cleanup scripts will delete themselves upon successful completion.

There are some helper scripts:


* [`query_entities.sh`](gateway_with_attached_sensor/query_entities.sh) provides examples of querying EdgeIQ for specific devices based on `unique_id` and that have a `demo` tag. More details on Query parameters [here](https://dev.edgeiq.io/docs/api-overrview#query-string-operators)
* [`diagslave_install.sh`](gateway_with_attached_sensor/diagslave_install.sh) is an example of how to install diagslave Modbus simulator as a systemd service. Must be run as root, e.g., `sudo ./diagslave_install.sh`. You can then use `journalctl -f --all -u diagslave` to follow logs. Note the `--all` options overcomes the `[xxB blob data]` by converting the binary output from diagslave.

The Modbus sensor/simulator and the HTTP Listener should be running **BEFORE** running these scripts.

### Gateway with Attached SNMP Sensor Device

This example shows how EdgeIQ can be configured to manage an edge gateway device with a connected SNMP sensor. The SNMP sensor is modeled as an attached device to the Gateway device. The sensor data will be forwarded to an HTTP listener. The [`httpprint.py`](gateway_with_attached_sensor_snmp/instance_files/httpprint.py) is an example of such a listener that will print out all HTTP messages that it receives.



Notes:

* These scripts were tested against the raspberry pi raspian running a gateway local `snmpd` installed by [`gateway_provision.sh`](gateway_with_attached_sensor_snmp/gateway_provision.sh)
* To use the included [`httpprint.py`](gateway_with_attached_sensor_snmp/instance_files/httpprint.py), you need to have a recent version of Python 3 installed. e.g. `python3 httpprint.py`
* To see the `httpprint.py` output, run on the gateway device, e.g. Raspberry Pi, the following command `journalctl -f -all -u httpprint`.

In `gateway_with_attached_sensor_snmp` subdirectory, run the following commands.

1. Run [`create_edgeiq_configuration.sh`](gateway_with_attached_sensor_snmp/create_edgeiq_configuration.sh). This will configure an EdgeIQ Device that can be used to remotely manage your gateway
2. Run [`gateway_provision.sh`](gateway_with_attached_sensor_snmp/gateway_provision.sh). This will install the EdgeIQ SmartEdge software onto the gateway and associate it with the EdgeIQ Device configured in the previous step.

The `create_edgeiq_configuration.sh` script will create a `cleanup-demo-<timestamp>.sh` file that contains API commands to delete EdgeIQ artifacts created by the create script. The cleanup scripts will delete themselves upon successful completion.

There are some helper scripts:

* [`query_entities.sh`](gateway_with_attached_sensor_snmp/query_entities.sh) provides examples of querying EdgeIQ for specific devices based on `unique_id` and that have a `demo` tag. More details on Query parameters [here](https://dev.edgeiq.io/docs/api-overrview#query-string-operators)
