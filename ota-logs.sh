#!/usr/bin/env bash
# Wireless logs for *this* device (vatrer-cerbo-ble). Do not use Furrion Chill Cube ota-logs.sh on this IP.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
[[ -n "${1:-}" ]] && export ESPHOME_OTA_HOST="$1"
exec "$ROOT/scripts/esphome-flash.sh" logs-ota
