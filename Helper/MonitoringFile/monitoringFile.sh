#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./monitoringFile.sh /folder/log [/path/to/config]
#
# Default config path:
#   ./monitoring_paths.conf (same folder as script)

LOG_DIR="${1:-}"
CONFIG_FILE="${2:-}"

if [[ -z "$LOG_DIR" ]]; then
  echo "Usage: $0 /folder/log [/path/to/config]"
  exit 1
fi

mkdir -p "$LOG_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_CONFIG="${SCRIPT_DIR}/monitoring_paths.conf"

if [[ -z "${CONFIG_FILE}" ]]; then
  CONFIG_FILE="$DEFAULT_CONFIG"
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: Config file not found: $CONFIG_FILE"
  exit 1
fi

DATE_YYYYMMDD="$(date +%Y%m%d)"
OUT_FILE="${LOG_DIR%/}/filecount_${DATE_YYYYMMDD}.txt"
NOW="$(date '+%Y-%m-%d %H:%M:%S')"

# Create header once per file
if [[ ! -f "$OUT_FILE" ]]; then
  echo "date_time,folder_name,filecount,foldercount" >> "$OUT_FILE"
fi

# Read config line by line
while IFS= read -r raw || [[ -n "$raw" ]]; do
  line="$(echo "$raw" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

  # Skip blanks or comments
  [[ -z "$line" ]] && continue
  [[ "$line" =~ ^# ]] && continue

  folder="$line"
  if [[ ! -d "$folder" ]]; then
    # If folder missing, still log it as 0/0 (or you can log as ERROR)
    echo "${NOW},${folder},0,0" >> "$OUT_FILE"
    continue
  fi

  # Count files and folders recursively (exclude the root folder itself from foldercount)
  filecount="$(find "$folder" -type f 2>/dev/null | wc -l | tr -d ' ')"
  foldercount="$(find "$folder" -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"

  echo "${NOW},${folder},${filecount},${foldercount}" >> "$OUT_FILE"
done < "$CONFIG_FILE"

echo "Wrote: $OUT_FILE"