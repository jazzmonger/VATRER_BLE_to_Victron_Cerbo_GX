# Cerbo GX MQTT BLE bridge (Vatrer / JBD)


ESP32-S3 firmware that reads two Vatrer (JBD) BMS units over BLE and publishes to a Victron Cerbo GX for **mr-manuel [dbus-mqtt-battery](https://github.com/mr-manuel/venus-os_dbus-mqtt-battery)**.

**Full setup, MQTT contract, troubleshooting, and DVCC:** see **[docs/CERBO-VATRER-SETUP.md](docs/CERBO-VATRER-SETUP.md)**.

## Quick start

```bash
cp secrets.yaml.example secrets.yaml   # edit WiFi, MQTT, esp32_ip
./scripts/esphome-flash.sh compile
./scripts/esphome-flash.sh upload      # or upload-ota after first USB flash
./ota-logs.sh                          # wireless logs (use this repo, not Furrion ota-logs.sh)
```

Cerbo: install/configure `dbus-mqtt-battery`, `topic = vatrer/battery`, select **Vatrer MQTT Battery** as battery monitor.
