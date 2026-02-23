#!/usr/bin/env bash
set -euo pipefail

read -r -p "1) Directory: " BASE_DIR
if [[ ! -d "$BASE_DIR" ]]; then
  echo "ERROR: Directory not found: $BASE_DIR"
  exit 1
fi

read -r -p "2) File name filter (optional, press Enter to skip): " NAME_FILTER
read -r -p "3) Content to search (word/sentence): " CONTENT

if [[ -z "${CONTENT// }" ]]; then
  echo "ERROR: Content to search cannot be empty."
  exit 1
fi

DATE_YYYYMMDD="$(date +%Y%m%d)"
OUT_FILE="contextSearch_${DATE_YYYYMMDD}.txt"

# Header
echo "no,fullpaths,linedetail" > "$OUT_FILE"

# Find name args (case-insensitive)
if [[ -n "$NAME_FILTER" ]]; then
  FIND_NAME_ARGS=(-iname "*${NAME_FILTER}*")
else
  FIND_NAME_ARGS=()
fi

# Temp output: "path<TAB>line"
TMP_OUT="$(mktemp)"
trap 'rm -f "$TMP_OUT"' EXIT

# -----------------------------
# Normal files: grep
# -R not used; we enumerate files to apply name filter safely
# -H include file name
# -n show line number
# We'll strip "path:lineNo:" prefix and keep line detail only
# -----------------------------
find "$BASE_DIR" -type f "${FIND_NAME_ARGS[@]}" ! -name "*.gz" -print0 2>/dev/null \
  | xargs -0 -r grep -Hn --binary-files=without-match -- "$CONTENT" 2>/dev/null \
  | awk -F: '{
      path=$1;
      # rebuild the matched line in case it contains ":" characters
      line="";
      for(i=3;i<=NF;i++){ line=line $i (i<NF? ":" : "") }
      print path "\t" line
    }' >> "$TMP_OUT" || true

# -----------------------------
# .gz files: zgrep (zcat-like)
# zgrep -Hn outputs: path:lineNo:line
# -----------------------------
find "$BASE_DIR" -type f "${FIND_NAME_ARGS[@]}" -name "*.gz" -print0 2>/dev/null \
  | xargs -0 -r zgrep -Hn -- "$CONTENT" 2>/dev/null \
  | awk -F: '{
      path=$1;
      line="";
      for(i=3;i<=NF;i++){ line=line $i (i<NF? ":" : "") }
      print path "\t" line
    }' >> "$TMP_OUT" || true

# Write numbered CSV, escaping quotes
n=0
while IFS=$'\t' read -r path line; do
  ((n++))
  # escape double quotes for CSV
  esc_path="${path//\"/\"\"}"
  esc_line="${line//\"/\"\"}"
  echo "${n},\"${esc_path}\",\"${esc_line}\"" >> "$OUT_FILE"
done < "$TMP_OUT"

echo "Wrote: $OUT_FILE"