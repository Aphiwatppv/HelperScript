#!/usr/bin/env python3
import os
import sys

def normalize_bool(choice: str) -> bool:
    return choice.strip() in ("1", "y", "Y", "yes", "YES", "Yes")

def contains(haystack: str, needle: str, case_insensitive: bool) -> bool:
    if case_insensitive:
        return needle.lower() in haystack.lower()
    return needle in haystack

def search_by_filename(base_dir: str, keyword: str, case_insensitive: bool):
    results = []
    for root, _, files in os.walk(base_dir):
        for name in files:
            if contains(name, keyword, case_insensitive):
                results.append(os.path.join(root, name))
    return results

def is_text_file(path: str) -> bool:
    # Heuristic: treat as text if it doesn't contain NUL and can be decoded as UTF-8 with replacement
    try:
        with open(path, "rb") as f:
            chunk = f.read(4096)
        if b"\x00" in chunk:
            return False
        return True
    except Exception:
        return False

def file_contains_keyword(path: str, keyword: str, case_insensitive: bool) -> bool:
    # Read line by line to avoid large memory usage
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            if case_insensitive:
                key = keyword.lower()
                for line in f:
                    if key in line.lower():
                        return True
            else:
                for line in f:
                    if keyword in line:
                        return True
        return False
    except Exception:
        return False

def search_by_file_content(base_dir: str, keyword: str, case_insensitive: bool):
    results = []
    for root, _, files in os.walk(base_dir):
        for name in files:
            path = os.path.join(root, name)
            if not is_text_file(path):
                continue
            if file_contains_keyword(path, keyword, case_insensitive):
                results.append(path)
    return results

def search_by_foldername(base_dir: str, keyword: str, case_insensitive: bool):
    results = []
    for root, dirs, _ in os.walk(base_dir):
        for d in dirs:
            if contains(d, keyword, case_insensitive):
                results.append(os.path.join(root, d))
    return results

def main():
    base_dir = input("Enter base directory (e.g. /srv/folderA): ").strip()
    if not os.path.isdir(base_dir):
        print(f"ERROR: Directory not found: {base_dir}")
        sys.exit(1)

    print("\nSelect function:")
    print("1) Search file NAME contains keyword")
    print("2) Search file CONTENT contains keyword")
    print("3) Search FOLDER NAME contains keyword")
    mode = input("Enter 1, 2 or 3: ").strip()

    print("\nCase sensitivity:")
    print("1) Case-INSENSITIVE")
    print("2) Case-SENSITIVE")
    case_mode = input("Enter 1 or 2: ").strip()
    case_insensitive = (case_mode == "1")

    keyword = input("\nSearch keyword: ").strip()
    print("\nResult:\n-------------------")

    if mode == "1":
        results = search_by_filename(base_dir, keyword, case_insensitive)
        for p in results:
            print(p)
        print(f"\nSummary\n{base_dir.rstrip('/')}/ : {len(results)} files")
        return

    if mode == "2":
        results = search_by_file_content(base_dir, keyword, case_insensitive)
        for p in results:
            print(p)
        print(f"\nSummary\n{base_dir.rstrip('/')}/ : {len(results)} files")
        return

    if mode == "3":
        results = search_by_foldername(base_dir, keyword, case_insensitive)
        for p in results:
            print(p)
        print(f"\nSummary\n{base_dir.rstrip('/')}/ : {len(results)} folders")
        return

    print("ERROR: Invalid selection. Please enter 1, 2, or 3.")
    sys.exit(1)

if __name__ == "__main__":
    main()