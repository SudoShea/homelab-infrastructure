#!/usr/bin/env python3
# ==============================================================================
# File        : scripts/bump_version.py
# Description : Automated semantic version bumper with recursive tree sync and smart git integration
# Author      : SudoShea
# Version     : 1.9.0
# License     : MIT
# ==============================================================================

import os
import re
import sys
import subprocess
from datetime import datetime

VERSION_FILE = "VERSION"
EXCLUDED_DIRS = {".git", ".github", "__pycache__", "venv", ".venv"}
EXCLUDED_FILES = {"CHANGELOG.md"}

def get_current_version():
    """Reads the current version from the master VERSION file."""
    if not os.path.exists(VERSION_FILE):
        print(f"Error: Could not find master version file at {VERSION_FILE}")
        sys.exit(1)
        
    with open(VERSION_FILE, "r", encoding="utf-8") as f:
        return f.read().strip()

def bump_version(current, bump_type):
    """Calculates the new semantic version."""
    try:
        major, minor, patch = map(int, current.split("."))
    except ValueError:
        print(f"Error: Existing version '{current}' is not a valid semantic version (X.Y.Z).")
        sys.exit(1)

    if bump_type == "major":
        return f"{major + 1}.0.0"
    elif bump_type == "minor":
        return f"{major}.{minor + 1}.0"
    elif bump_type == "patch":
        return f"{major}.{minor}.{patch + 1}"
    else:
        if re.match(r"^[0-9]+\.[0-9]+\.[0-9]+$", bump_type):
            return bump_type
        print(f"Invalid bump type or version format: {bump_type}")
        sys.exit(1)

def find_version_files():
    """Recursively walks the repository to find code comments or Markdown metadata with version headers."""
    matching_files = []
    code_pattern = re.compile(r"#\s*Version\s*[:\s]*[0-9]+\.[0-9]+\.[0-9]+")
    md_pattern = re.compile(r"[\*\-]\s*\*\*Version:\*\*\s*[0-9]+\.[0-9]+\.[0-9]+")

    for root, dirs, files in os.walk("."):
        dirs[:] = [d for d in dirs if d not in EXCLUDED_DIRS]

        for file in files:
            if file in EXCLUDED_FILES:
                continue

            filepath = os.path.join(root, file)
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read()
                    if code_pattern.search(content) or md_pattern.search(content):
                        matching_files.append(filepath)
            except (UnicodeDecodeError, PermissionError):
                continue

    return sorted(matching_files)

def update_repository(new_version, target_files):
    """Updates the master VERSION file and dynamically updates all discovered headers and Markdown metadata."""
    today_date = datetime.now().strftime("%Y-%m-%d")

    # 1. Update master VERSION file
    with open(VERSION_FILE, "w", encoding="utf-8") as f:
        f.write(new_version + "\n")
    print(f"Updated master source : {VERSION_FILE} -> v{new_version}")

    # 2. Patterns for code comments and Markdown runbook metadata
    code_pattern = re.compile(r"(#\s*Version\s*[:\s]*)[0-9]+\.[0-9]+\.[0-9]+")
    md_ver_pattern = re.compile(r"([\*\-]\s*\*\*Version:\*\*\s*)[0-9]+\.[0-9]+\.[0-9]+")
    md_date_pattern = re.compile(r"([\*\-]\s*\*\*Last Updated:\*\*\s*)[0-9]{4}-[0-9]{2}-[0-9]{2}")

    for filepath in target_files:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()

        # Apply code header update
        new_content = code_pattern.sub(lambda m: m.group(1) + new_version, content)
        # Apply Markdown runbook metadata updates
        new_content = md_ver_pattern.sub(lambda m: m.group(1) + new_version, new_content)
        new_content = md_date_pattern.sub(lambda m: m.group(1) + today_date, new_content)

        with open(filepath, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"Synchronised header   : {filepath}")

    print(f"\nSuccessfully updated repository version to v{new_version} across all tracked files.")

def execute_git_workflow(version):
    """Automates git add, commit, tag, and push with smart commit message generation and remote tag protection."""
    print("\n--- Executing Git Workflow ---")

    tag_name = f"v{version}"
    tag_msg = f"Release {tag_name}"

    try:
        # 1. Stage all changes first so we can inspect them
        subprocess.run(["git", "add", "-A"], check=True)

        # 2. Inspect staged files to auto-generate a smart compound conventional commit message
        status_res = subprocess.run(["git", "status", "--porcelain"], capture_output=True, text=True, check=True)
        staged_files = status_res.stdout

        components = []
        if "scripts/" in staged_files:
            components.append("fix(scripts)")
        if "CHANGELOG.md" in staged_files:
            components.append("docs(changelog)")
        if "README.md" in staged_files:
            components.append("docs(readme)")
        if "tasks/" in staged_files or "defaults/" in staged_files:
            components.append("refactor(hardening)")
        if "inventory" in staged_files or "group_vars" in staged_files:
            components.append("chore(config)")

        # Build the smart default suggestion
        if components:
            prefix = "/".join(components)
            default_msg = f"{prefix}: bump version to v{version}"
        else:
            default_msg = f"chore(release): bump version to v{version}"

    except Exception:
        default_msg = f"chore(release): bump version to v{version}"

    # Prompt user with the intelligent suggestion (Press Enter to accept)
    print(f"\nSuggested Commit Message:")
    commit_msg = input(f"[{default_msg}]: ").strip()
    if not commit_msg:
        commit_msg = default_msg

    try:
        # 3. Commit changes (Handle gracefully if no new changes exist)
        commit_res = subprocess.run(["git", "commit", "-m", commit_msg])
        if commit_res.returncode != 0:
            print("-> No new changes to commit. Proceeding to tag/push...")
        else:
            print(f"-> Committed with message: '{commit_msg}'")

        # 4. Check if tag exists locally or remotely
        local_check = subprocess.run(["git", "rev-parse", "--verify", f"refs/tags/{tag_name}"], capture_output=True, text=True)
        remote_check = subprocess.run(["git", "ls-remote", "--exit-code", "--tags", "origin", tag_name], capture_output=True, text=True)
        
        tag_local = (local_check.returncode == 0)
        tag_remote = (remote_check.returncode == 0)

        if tag_local or tag_remote:
            print(f"\nWarning: Tag '{tag_name}' already exists (Local: {tag_local}, Remote: {tag_remote}).")
            overwrite = input("Do you want to overwrite/re-push the tag? [y/N]: ").strip().lower()
            if overwrite == 'y':
                if tag_local:
                    subprocess.run(["git", "tag", "-d", tag_name], check=True)
                    print(f"-> Deleted local tag {tag_name}")
                if tag_remote:
                    subprocess.run(["git", "push", "origin", "--delete", tag_name], check=True)
                    print(f"-> Deleted remote tag {tag_name}")
                
                # Create fresh local tag
                subprocess.run(["git", "tag", "-a", tag_name, "-m", tag_msg], check=True)
                print(f"-> Re-created annotated tag: {tag_name}")
            else:
                print("-> Skipping tag sync. Pushing code only.")
                subprocess.run(["git", "push", "origin", "main"], check=True)
                print("-> Successfully pushed changes to remote (origin main).")
                return

        else:
            # Create annotated git tag if it doesn't exist anywhere
            subprocess.run(["git", "tag", "-a", tag_name, "-m", tag_msg], check=True)
            print(f"-> Created annotated tag: {tag_name}")

        # 5. Push to remote origin main with tags
        subprocess.run(["git", "push", "origin", "main", "--tags"], check=True)
        print("-> Successfully pushed changes and tags to remote (origin main).")

    except subprocess.CalledProcessError as e:
        print(f"Error during git workflow execution: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 scripts/bump_version.py [patch|minor|major|X.Y.Z]")
        sys.exit(1)

    bump_arg = sys.argv[1]
    current_ver = get_current_version()
    new_ver = bump_version(current_ver, bump_arg)

    target_files = find_version_files()

    print(f"Current version : {current_ver}")
    print(f"Target version  : {new_ver}\n")

    print("Discovered files with version headers:")
    if target_files:
        for tf in target_files:
            print(f"  - {tf}")
    else:
        print("  (None found)")

    confirm = input("\nProceed with version update and file synchronisation? [y/N]: ").strip().lower()
    if confirm == 'y':
        update_repository(new_ver, target_files)

        git_confirm = input("\nDo you want to run the automated git workflow (add, commit, tag, push)? [y/N]: ").strip().lower()
        if git_confirm == 'y':
            execute_git_workflow(new_ver)
        else:
            print("Git workflow skipped. Files updated locally.")
    else:
        print("Version bump aborted.")
