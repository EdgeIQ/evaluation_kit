# EdgeIQ Evaluation Kit

## Requirements


Bash scripts are executed from a host, and will use SSH to connect & install the edge software on your gateway device. these scripts can be run from the gateway device itself, but this has not been thoroughly tested.

* `bash` - version 4.x or newer
* `curl` - tested against curl version 7.64.1
* `jq` - tested against version 1.6. See: <https://stedolan.github.io/jq>


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
<details>
<summary>Expand</summary>
In `simple_gateway` subdirectory, run the following commands.

1. Run [`create_edgeiq_configuration.sh`](simple_gateway/create_edgeiq_configuration.sh). This will configure an EdgeIQ Device that can be used to remotely manage your gateway
2. Run [`gateway_provision.sh`](simple_gateway/gateway_provision.sh). This will install the EdgeIQ SmartEdge software onto the gateway and associate it with the EdgeIQ Device configured in the previous step.

The `create_edgeiq_configuration.sh` script will create a `cleanup-demo-<timestamp>.sh` file that contains API commands to delete EdgeIQ artifacts created by the create script. The cleanup scripts will delete themselves upon successful completion.

There is a helper script [`query_entities.sh`](simple_gateway/query_entities.sh) that provides examples of various ways to query artifacts from EdgeIQ.
</details>

### Gateway with ModBus Sensor Device
<details>
<summary>Expand</summary>
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
</details>

### Gateway with Attached ModBus Sensor Device
<details>
<summary>Expand</summary>
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
</details>

### Gateway with Attached SNMP Sensor Device
<details>
<summary>Expand</summary>
This example shows how EdgeIQ can be configured to manage an edge gateway device with a connected SNMP sensor. The SNMP sensor is modeled as an attached device to the Gateway device. The sensor data will be forwarded to an HTTP listener. The [`httpprint.py`](gateway_with_attached_sensor_snmp/instance_files/httpprint.py) is an example of such a listener that will print out all HTTP messages that it receives.



Notes:

* These scripts were tested against the Raspberry Ri Raspian (Raspberry Pi OS) running a gateway local `snmpd` installed by [`gateway_provision.sh`](gateway_with_attached_sensor_snmp/gateway_provision.sh)
* To use the included [`httpprint.py`](gateway_with_attached_sensor_snmp/instance_files/httpprint.py), you need to have a recent version of Python 3 installed. e.g. `python3 httpprint.py`
* To see the `httpprint.py` output, run on the gateway device, e.g. Raspberry Pi, the following command `journalctl -f -all -u httpprint`.

In `gateway_with_attached_sensor_snmp` subdirectory, run the following commands.

1. Run [`create_edgeiq_configuration.sh`](gateway_with_attached_sensor_snmp/create_edgeiq_configuration.sh). This will configure an EdgeIQ Device that can be used to remotely manage your gateway
2. Run [`gateway_provision.sh`](gateway_with_attached_sensor_snmp/gateway_provision.sh). This will install the EdgeIQ SmartEdge software onto the gateway and associate it with the EdgeIQ Device configured in the previous step.

The `create_edgeiq_configuration.sh` script will create a `cleanup-demo-<timestamp>.sh` file that contains API commands to delete EdgeIQ artifacts created by the create script. The cleanup scripts will delete themselves upon successful completion.

There are some helper scripts:

* [`query_entities.sh`](gateway_with_attached_sensor_snmp/query_entities.sh) provides examples of querying EdgeIQ for specific devices based on `unique_id` and that have a `demo` tag. More details on Query parameters [here](https://dev.edgeiq.io/docs/api-overrview#query-string-operators)

</details>

### Gateway with Attached Ping/Latency Sensor Device Using Shell Polling
<details>
<summary>Expand</summary>
This example shows how EdgeIQ can be configured to manage an edge gateway device with a connected latency sensor (i.e. ping a downstream device from the gateway). The latency sensor is modeled as an attached device to the Gateway device, with an attached Ingestor that performs the shell polling.


1. Run [`create_edgeiq_configuration.sh`](gateway_with_attached_sensor_ping/create_edgeiq_configuration.sh). This will configure an EdgeIQ Device for Gateway and Sensor, Device Types for each, Ingestor, Translator, and Policies that can be used to remotely manage your gateway and endpoint devices.
2. Run [`gateway_provision.sh`](gateway_with_attached_sensor_ping/gateway_provision.sh). This will install the EdgeIQ SmartEdge software onto the gateway and associate it with the EdgeIQ Device configured in the previous step.

The `create_edgeiq_configuration.sh` script will create a `cleanup-demo-<timestamp>.sh` file that contains API commands to delete EdgeIQ artifacts created by the create script. The cleanup scripts will delete themselves upon successful completion.
</details>

### Gateway with Software Update
<details>
<summary>Expand</summary>
This example shows how to create and send a Software Update command in the EdgeIQ platform.


1. Run [`create_edgeiq_configuration.sh`](gateway_with_attached_sensor_ping/create_edgeiq_configuration.sh). This will configure an EdgeIQ Device for Gateway and Sensor, Device Types for each, Ingestor, Translator, and Policies that can be used to remotely manage your gateway and endpoint devices.
2. Run [`gateway_provision.sh`](gateway_with_attached_sensor_ping/gateway_provision.sh). This will install the EdgeIQ SmartEdge software onto the gateway and associate it with the EdgeIQ Device configured in the previous step.

The `create_edgeiq_configuration.sh` script will create a `cleanup-demo-<timestamp>.sh` file that contains API commands to delete EdgeIQ artifacts created by the create script. The cleanup scripts will delete themselves upon successful completion.
</details>

### Transferring Escrow Devices

<details>

<summary>Expand</summary>

This example walks through the process to onboard and transfer an Escrow Device. See:
https://dev.edgeiq.io/docs/escrow-devices-and-transfers
https://files.readme.io/ae55db6-escrow_workflow.png

This script will perform the following actions:

 - Create two subaccounts under your account: "Demo Manufacturer" and "Demo Customer"
 - Create a User for each subaccount
 - Create Device Type & Device in "Demo Manufacturer" account
 - Provision gateway device & create token ID on device: `/opt/escrow_token`
 - Create Escrow Device on "Demo Manufacturer"
 - Create Device Transfer Request on "Demo Manufacturer"
 - Get Device Transfer Request Status/Errors on "Demo Manufacturer"
 - Accept devices on "Demo Customer" subaccounts
 - Create Software Update & execute on device

Steps involved:
1. Run [`step1_create_escrow`](gateway_with_attached_sensor_ping/create_edgeiq_configuration.sh). This will configure an EdgeIQ Device for Gateway and Sensor, Device Types for each, Ingestor, Translator, and Policies that can be used to remotely manage your gateway and endpoint devices.
2. Run [`step2_gateway_provision.sh`](gateway_with_attached_sensor_ping/gateway_provision.sh). This will install the EdgeIQ SmartEdge software onto the gateway and associate it with the EdgeIQ Device configured in the previous step.
3. Run [`step3_gateway_provision.sh`](gateway_with_attached_sensor_ping/gateway_provision.sh). This will install the EdgeIQ SmartEdge software onto the gateway and associate it with the EdgeIQ Device configured in the previous step.


The `create_edgeiq_configuration.sh` script will create a `cleanup-demo-<timestamp>.sh` file that contains API commands to delete EdgeIQ artifacts created by the create script. The cleanup scripts will delete themselves upon successful completion.
</details>
