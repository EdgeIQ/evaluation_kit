# EdgeIQ Evaluation Kit

## Requirements to run these scripts

* `curl` - tested against curl version 7.64.1
* `jq` - tested against version 1.6. Installation and documentation at <https://stedolan.github.io/jq>

## Setup

Update the [`setenv.sh`](setenv.sh) file with your

* EdgeIQ username and password
* Your gateway device MAC address and associated IP address
* Configure EdgeIQ Device Type - defaults to Raspberry Pi 3/4 running recent Debian/Ubuntu linux

## Examples

EdgeIQ Portal: <https://app.edgeiq.io>
EdgeIQ API Base URL: <https://api.edgeiq.io/api/v1/platform>
EdgeIQ Documentation: <https://dev.edgeiq.io/>

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

This example shows how EdgeIQ can be configured to manage an edge gateway device with a connected Modbus sensor. The sensor data will be forwarded to an HTTP listener. The [`httpprint.py`](httpprint.py) is an example of such a listener that will print out all HTTP messages that it receives.

Notes:

* These scripts were tested against the free [diagslave](https://www.modbusdriver.com/diagslave.html) Modbus simulator, e.g. `diagslave -m tcp`.
* To use the included [`httpprint.py`](httpprint.py), you need to have a recent version of Python 3 installed. e.g. `python3 httpprint.py`
* To see the `httpprint.py` output, run on the gateway device, e.g. Raspberry Pi, the following command `journalctl -f -all -u httpprint`.

In `simple_gateway` subdirectory, run the following commands.

1. Run [`create_edgeiq_configuration.sh`](simple_gateway/create_edgeiq_configuration.sh). This will configure an EdgeIQ Device that can be used to remotely manage your gateway
2. Run [`gateway_provision.sh`](simple_gateway/gateway_provision.sh). This will install the EdgeIQ SmartEdge software onto the gateway and associate it with the EdgeIQ Device configured in the previous step.

The `create_edgeiq_configuration.sh` script will create a `cleanup-demo-<timestamp>.sh` file that contains API commands to delete EdgeIQ artifacts created by the create script. The cleanup scripts will delete themselves upon successful completion.


There are some helper scripts:

* [`list_entities.sh`](list_entities.sh) that will display all the various EdgeIQ objects you have access to within your account.
* [`query_devices.sh`](query_devices.sh) provides examples of querying EdgeIQ for specific devices based on `unique_id` and that have a `poc` tag. More details on Query parameters [here](https://documentation.machineshop.io/guides/api_overview)
* [`query_reports.sh`](query_reports.sh) gets the latest Sensor data
* [`install_diagslave.sh`](install_diagslave.sh) is an example of how to install diagslave Modbus simulator as a systemd service. Must be run as root, e.g., `sudo ./install_diagslave.sh`. You can then use `journalctl -f --all -u diagslave` to follow logs. Note the `--all` options overcomes the `[xxB blob data]` by converting the binary output from diagslave.

The Modbus sensor/simulator and the HTTP Listener should be running **BEFORE** running these scripts.

