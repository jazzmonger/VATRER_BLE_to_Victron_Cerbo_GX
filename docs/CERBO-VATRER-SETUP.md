# Vatrer BLE → Cerbo GX (mr-manuel MQTT battery)

ESP32-S3 reads two JBD (Vatrer) BMS packs over BLE and publishes data to the Cerbo’s MQTT broker. The Cerbo runs **[mr-manuel venus-os_dbus-mqtt-battery](https://github.com/mr-manuel/venus-os_dbus-mqtt-battery)** (PackageManager), **not** the separate [victron-venus/dbus-mqtt-battery](https://github.com/victron-venus/dbus-mqtt-battery) project (different topic layout).

## System layout

```
  BMS 1 (BLE) ──┐
                ├── ESP32 (ESPHome) ──MQTT──► Cerbo Mosquitto (localhost)
  BMS 2 (BLE) ──┘                              │
                                                 ▼
                                    dbus-mqtt-battery (D-Bus battery)
                                                 │
                                                 ▼
                                    GX UI / DVCC / ESS (battery monitor)
```

**Electrical model (this install):** two **12 V (4S LiFePO₄)** packs in **parallel** on one 12 V bus. Bank voltage ≈ one pack (~13–14 V), not the sum of both packs.

**Firmware assumptions** (`vatrer-cerbo-ble.yaml` substitutions):

| Key | Value | Meaning |
|-----|-------|---------|
| `cells_per_pack` | `4` | Sum first 4 cell voltages per BMS for pack voltage |
| `installed_capacity_ah` | `600` | Parallel Ah (2×300 Ah); change if your bank differs |
| `mqtt_prefix` | `vatrer/battery` | Cerbo `config.ini` topic must match exactly |

Pack voltage: sum of 4 cells (or JBD `total_voltage` fallback when 10–16.5 V).  
Bank voltage: **average** of pack 1 and pack 2 (parallel), not series sum.

---

## MQTT contract (mr-manuel)

The driver subscribes to **one topic** with a **single JSON object** (not ESPHome `/sensor/.../state` topics).

| Item | Value |
|------|--------|
| Topic | `vatrer/battery` — **no** leading `/` (must match `config.ini`) |
| Retain | `true` (overwrites stale payloads after config changes) |
| Minimum JSON | `{"Dc":{"Power":0,"Voltage":13.4},"Soc":93}` |

Optional debug: ESPHome still publishes `vatrer/battery/sensor/...` for local inspection; the Cerbo driver ignores those.

**Future (DVCC limits from BMS):** mr-manuel can use:

```json
"Info": {
  "MaxChargeVoltage": 14.4,
  "MaxChargeCurrent": 80,
  "MaxDischargeCurrent": 120
}
```

Not sent by firmware yet — set charge limits on Multi/MPPT and in DVCC manually until added in YAML.

---

## Cerbo: dbus-mqtt-battery

**Config file:** `/data/etc/dbus-mqtt-battery/config.ini`

Example (adjust names/instance as needed):

```ini
[DEFAULT]
logging = WARNING
device_name = Vatrer MQTT Battery
device_instance = 100
timeout = 120

[MQTT]
broker_address = localhost
broker_port = 1883
topic = vatrer/battery
```

- **`timeout`:** BLE poll can exceed 60 s; use **120** (or `0` to disable) if the service exits with “Timeout of 60 seconds exceeded”.
- **`topic`:** must equal ESP `mqtt_prefix` with **no** leading slash.

**Install / restart / logs:**

```bash
bash /data/etc/dbus-mqtt-battery/install.sh   # first time only
bash /data/etc/dbus-mqtt-battery/restart.sh
tail -n 50 -F /data/log/dbus-mqtt-battery/current | tai64nlocal
```

**Verify MQTT on Cerbo:**

```bash
mosquitto_sub -h localhost -t 'vatrer/battery' -v -C 1
```

Expect `"Voltage":13.xx` for a 12 V bank, not ~107 V.

**GX battery monitor:** Settings → System setup → Battery → **Vatrer MQTT Battery**.

**Driver log format** (three values):

`Battery: <power> W - <voltage> V - <soc> %`

Negative “voltages” in a mislabeled view are often **watts** (discharge).

---

## ESP32: secrets and flash

Copy `secrets.yaml.example` → `secrets.yaml` (gitignored).

| Secret | Purpose |
|--------|---------|
| `wifi_ssid` / `wifi_pass` | RV Wi‑Fi |
| `mqtt_broker` | Cerbo IP (e.g. `192.168.2.220`) |
| `mqtt_username` / `mqtt_password` | Cerbo MQTT user (e.g. `remoteconsole`) |
| `esp32_ip` | OTA/logs without prompts (e.g. `192.168.2.91`) |

**Commands** (from project root):

```bash
./scripts/esphome-flash.sh compile
./scripts/esphome-flash.sh upload          # USB: ESPHOME_DEVICE=/dev/cu.usbmodem1101 if needed
./scripts/esphome-flash.sh upload-ota
./scripts/esphome-flash.sh logs-ota
```

Build path: `~/ESPHome_Projects/cerbo-vatrer-esphome-build` (avoids spaces in project folder name).

Global ESPHome: `~/ESPHome_Projects/esphome-global/.venv/bin/esphome` (2026.9.0).

**OTA logs:** Run from **this project** (not Furrion Chill Cube):

```bash
./scripts/esphome-flash.sh logs-ota
# or: ./ota-logs.sh
# or: ./ota-logs.sh 192.168.2.91
```

Uses `vatrer-cerbo-ble.yaml` and ESPHome **2026.9** (global venv). With `esp32_ip` in `secrets.yaml`, logs connect by IP. Without it, ESPHome may prompt for MQTT vs mDNS.

This firmware uses a **plaintext** native API (no `api.encryption` block). If you see `EncryptionPlaintextAPIError` or logs label the device `furrion-chill-cube`, you are using the wrong YAML or an old ESPHome client (e.g. Furrion’s `ota-logs.sh` with API encryption).

**Firmware log line when Cerbo JSON is sent:**

`[I][cerbo]: MQTT JSON V=13.xx P=... Soc=...`

---

## BMS BLE

| BMS | MAC |
|-----|-----|
| 1 | `A5:C2:39:52:70:FB` |
| 2 | `A5:C2:39:52:70:F4` |

Sequential connect → read → disconnect (one BMS at a time). Status **133** on the second pack: longer delays, range, close phone app on that BMS.

JBD component: [syssi/esphome-jbd-bms](https://github.com/syssi/esphome-jbd-bms) `@main`.

---

## Troubleshooting

| Symptom | Likely cause | Action |
|---------|----------------|--------|
| Driver timeout, no data | Wrong topic (`/vatrer/battery` vs `vatrer/battery`) or no JSON | Fix topic; check `mosquitto_sub`; wait for BLE poll / `cerbo` log line |
| Tile shows **~107 V** | Old **retained** JSON from 16S-series math | OTA current firmware; `restart.sh`; confirm retained message ~13 V |
| ESP shows **13.5 V**, tile wrong | Retained MQTT not updated yet | Publish on each BMS read + 15 s interval; restart driver |
| MQTT `0x5` | Bad Cerbo MQTT credentials | Match `secrets.yaml` to Cerbo MQTT settings |
| `voltage_bms*` ~13 V but cells ~3.3 V × 4 | Normal for 4S; ignore scaling `total_voltage` for bank math | Bank uses cell sum / average |
| Wrong high voltage in history | Summed two packs as series or scaled 4 cells to 16S | Fixed in firmware: 4 cells, parallel average |
| OTA logs: **plaintext protocol** / `furrion-chill-cube @ 192.168.2.91` | Wrong project script on Vatrer bridge IP | `cd` this repo; `./ota-logs.sh` or `./scripts/esphome-flash.sh logs-ota` |

---

## DVCC (when to enable and settings)

**Prerequisites**

1. Battery monitor = **Vatrer MQTT Battery**.
2. Tile ~**12.5–14.5 V**, SOC plausible.
3. `mosquitto_sub` shows sane JSON on `vatrer/battery`.

**Should you enable DVCC?**

Reasonable for **ESS / Multi + MPPT** so the GX coordinates chargers. This MQTT battery is **not** a Victron CAN BMS from the battery compatibility manual — **charge voltage/current limits are not fully driven by the JBD over MQTT yet** (no `Info` block). Set **LiFePO₄** on Multi/MPPT and limits in **DVCC** manually; JBD still protects at the pack.

**Suggested starting point (12 V LiFePO₄, ESS)**

| Setting | Suggestion |
|---------|------------|
| DVCC | **On** (after voltage/SOC stable) |
| Charge voltage limit | **~14.2–14.4 V** (confirm with Vatrer/installer) |
| Max charge current | Bank limit (wiring/inverter/BMS) |
| Max discharge current | Same, per capability |
| Shared voltage sense (SVS) | **Off** with ESS (typical) |
| Shared current sense (SCS) | **Off** with ESS; On only with BMV/SmartShunt in non-ESS setups per Victron docs |
| Multi / MPPT profile | LiFePO₄; absorption ≤ 14.4 V, float ~13.6 V |

Official reference: [Cerbo GX manual — DVCC](https://www.victronenergy.com/media/pg/Cerbo_GX/en/dvcc---distributed-voltage-and-current-control.html).

**Order of operations:** confirm tile → set Multi/MPPT LiFePO₄ → enable DVCC → set voltage/current limits → watch one full charge cycle.

---

## Related files

| File | Role |
|------|------|
| `vatrer-cerbo-ble.yaml` | Firmware |
| `scripts/esphome-flash.sh` | Compile / USB / OTA / logs |
| `secrets.yaml` | Credentials (not in git) |
| `.cursor/rules/esphome-*.mdc` | ESPHome path and flash conventions |

---

## Changelog (project notes)

- **2026-09-27:** mr-manuel JSON on `vatrer/battery`; 12 V parallel voltage; immediate publish on BMS read; retained MQTT; cell-sum pack voltage; DVCC guidance documented.
