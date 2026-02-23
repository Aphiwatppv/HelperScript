#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Linux Search Tool
# 1) Search by filename (contains keyword) -> full paths
# 2) Search by file content (contains keyword) -> full paths (each file once)
# 3) Search folder name (contains keyword) -> full paths
# -----------------------------

read -r -p "Enter base directory (e.g. /srv/folderA): " BASE_DIR

if [[ ! -d "${BASE_DIR}" ]]; then
  echo "ERROR: Directory not found: ${BASE_DIR}"
  exit 1
fi

echo ""
echo "Select function:"
echo "1) Search file NAME contains keyword"
echo "2) Search file CONTENT contains keyword"
echo "3) Search FOLDER NAME contains keyword"
read -r -p "Enter 1, 2 or 3: " MODE

echo ""
read -r -p "Search keyword: " KEYWORD

# Helper: print paths + summary
print_summary() {
  local count="$1"
  local label="$2"
  echo ""
  echo "Summary"
  echo "${BASE_DIR%/}/ : ${count} ${label}"
}

# ---- MODE 1: filename contains keyword (case-insensitive) ----
if [[ "${MODE}" == "1" ]]; then
  mapfile -d '' RESULTS < <(find "${BASE_DIR}" -type f -iname "*${KEYWORD}*" -print0 2>/dev/null || true)

  if (( ${#RESULTS[@]} == 0 )); then
    echo "No files found (name contains: ${KEYWORD})"
    print_summary 0 "files"
    exit 0
  fi

  for f in "${RESULTS[@]}"; do
    echo "$f"
  done

  print_summary "${#RESULTS[@]}" "files"
  exit 0
fi

# ---- MODE 2: file content contains keyword (case-insensitive) ----
if [[ "${MODE}" == "2" ]]; then
  mapfile -d '' RESULTS < <(grep -RIl --null -i -- "${KEYWORD}" "${BASE_DIR}" 2>/dev/null || true)

  if (( ${#RESULTS[@]} == 0 )); then
    echo "No files found (content contains: ${KEYWORD})"
    print_summary 0 "files"
    exit 0
  fi

  for f in "${RESULTS[@]}"; do
    echo "$f"
  done

  print_summary "${#RESULTS[@]}" "files"
  exit 0
fi

# ---- MODE 3: folder name contains keyword (case-insensitive) ----
if [[ "${MODE}" == "3" ]]; then
  # -mindepth 1: exclude the base dir itself
  mapfile -d '' RESULTS < <(find "${BASE_DIR}" -mindepth 1 -type d -iname "*${KEYWORD}*" -print0 2>/dev/null || true)

  if (( ${#RESULTS[@]} == 0 )); then
    echo "No folders found (name contains: ${KEYWORD})"
    print_summary 0 "folders"
    exit 0
  fi

  for d in "${RESULTS[@]}"; do
    echo "$d"
  done

  print_summary "${#RESULTS[@]}" "folders"
  exit 0
fi

echo "ERROR: Invalid selection. Please enter 1, 2, or 3."
exit 1