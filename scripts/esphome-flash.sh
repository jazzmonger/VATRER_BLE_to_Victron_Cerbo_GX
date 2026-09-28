#!/usr/bin/env bash
set -euo pipefail
export PYTHONUNBUFFERED=1

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIG="${ESPHOME_CONFIG:-vatrer-cerbo-ble.yaml}"
DEVICE="${ESPHOME_DEVICE:-/dev/cu.usbmodem101}"
export ESPHOME_BUILD_PATH="${ESPHOME_BUILD_PATH:-$HOME/ESPHome_Projects/cerbo-vatrer-esphome-build}"
export PLATFORMIO_BUILD_CACHE_DIR="${PLATFORMIO_BUILD_CACHE_DIR:-$HOME/.cache/platformio-esphome}"
mkdir -p "$ESPHOME_BUILD_PATH" "$PLATFORMIO_BUILD_CACHE_DIR"

find_esphome() {
  local candidates=()
  [[ -n "${ESPHOME_BIN:-}" ]] && candidates+=("$ESPHOME_BIN")
  candidates+=(
    "$HOME/ESPHome_Projects/esphome-global/.venv/bin/esphome"
    "/usr/local/bin/esphome"
    "/opt/homebrew/bin/esphome"
    "$HOME/.local/bin/esphome"
  )
  if command -v esphome &>/dev/null; then
    candidates+=("$(command -v esphome)")
  fi

  local bin ver
  for bin in "${candidates[@]}"; do
    [[ -x "$bin" ]] || continue
    ver="$("$bin" version 2>/dev/null)" || continue
    echo "$bin"
    return
  done
  echo "No working esphome found. Set ESPHOME_BIN to your existing install." >&2
  exit 1
}

resolve_ota_host() {
  if [[ -n "${ESPHOME_OTA_HOST:-}" ]]; then
    return 0
  fi
  if [[ -f secrets.yaml ]]; then
    local ip
    ip="$(grep -E '^esp32_ip:' secrets.yaml 2>/dev/null | sed -E 's/^esp32_ip:[[:space:]]*"?([^"#]+)"?.*/\1/' | tr -d ' ' || true)"
    if [[ -n "$ip" && "$ip" != '""' ]]; then
      export ESPHOME_OTA_HOST="$ip"
    fi
  fi
}

ESPHOME_BIN="$(find_esphome)"
export ESPHOME_BIN
resolve_ota_host

echo "Using: $ESPHOME_BIN ($("$ESPHOME_BIN" version))"
echo "Config: $CONFIG  USB: $DEVICE  Build: $ESPHOME_BUILD_PATH"
[[ -n "${ESPHOME_OTA_HOST:-}" ]] && echo "OTA host: $ESPHOME_OTA_HOST"

cmd="${1:-upload}"
case "$cmd" in
  config)
    "$ESPHOME_BIN" config "$CONFIG"
    ;;
  compile)
    "$ESPHOME_BIN" compile "$CONFIG"
    ;;
  upload)
    "$ESPHOME_BIN" upload "$CONFIG" --device "$DEVICE"
    ;;
  run)
    "$ESPHOME_BIN" run "$CONFIG" --device "$DEVICE"
    ;;
  logs)
    "$ESPHOME_BIN" logs "$CONFIG" --device "$DEVICE"
    ;;
  upload-ota)
    if [[ -z "${ESPHOME_OTA_HOST:-}" ]]; then
      echo "Set ESPHOME_OTA_HOST or esp32_ip in secrets.yaml" >&2
      exit 1
    fi
    "$ESPHOME_BIN" upload "$CONFIG" --device "$ESPHOME_OTA_HOST"
    ;;
  run-ota)
    if [[ -z "${ESPHOME_OTA_HOST:-}" ]]; then
      echo "Set ESPHOME_OTA_HOST or esp32_ip in secrets.yaml" >&2
      exit 1
    fi
    "$ESPHOME_BIN" run "$CONFIG" --device "$ESPHOME_OTA_HOST"
    ;;
  logs-ota)
    if [[ -n "${ESPHOME_OTA_HOST:-}" ]]; then
      "$ESPHOME_BIN" logs "$CONFIG" --device "$ESPHOME_OTA_HOST"
    else
      echo "No ESPHOME_OTA_HOST — trying mDNS (vatrer-cerbo-ble.local)..."
      "$ESPHOME_BIN" logs "$CONFIG"
    fi
    ;;
  *)
    echo "Usage: $0 {config|compile|upload|run|logs|upload-ota|run-ota|logs-ota}" >&2
    exit 1
    ;;
esac
