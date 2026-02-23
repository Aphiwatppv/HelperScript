#!/usr/bin/env python3
import os
import gzip
import sys

def name_match(filename: str, name_filter: str) -> bool:
    if not name_filter:
        return True
    return name_filter.lower() in filename.lower()

def content_in_text_file(path: str, needle: str) -> bool:
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                if needle in line:
                    return True
    except Exception:
        return False
    return False

def content_in_gz_file(path: str, needle: str) -> bool:
    try:
        with gzip.open(path, "rt", encoding="utf-8", errors="ignore") as f:
            for line in f:
                if needle in line:
                    return True
    except Exception:
        return False
    return False

def main():
    base_dir = input("1) Directory: ").strip()
    if not os.path.isdir(base_dir):
        print(f"ERROR: Directory not found: {base_dir}")
        sys.exit(1)

    name_filter = input("2) File name filter (optional, press Enter to skip): ").strip()
    needle = input("3) Content to search (word/sentence): ").strip()
    if not needle:
        print("ERROR: Content keyword cannot be empty.")
        sys.exit(1)

    print("\nResult:\n-------------------")
    results = []

    for root, _, files in os.walk(base_dir):
        for fn in files:
            if not name_match(fn, name_filter):
                continue

            path = os.path.join(root, fn)

            if fn.endswith(".gz"):
                if content_in_gz_file(path, needle):
                    results.append(path)
            else:
                if content_in_text_file(path, needle):
                    results.append(path)

    for p in results:
        print(p)

    print(f"\nSummary\n{base_dir.rstrip('/')}/ : {len(results)} files")

if __name__ == "__main__":
    main()