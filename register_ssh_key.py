#!/usr/bin/env python3
"""
Register the local vast.ai SSH key with your vast.ai account.

Reads:
  - API key from ~/.vast_api_key
  - Public key from ~/.ssh/vastai.pub

Run this once after setup, or again if you regenerate your SSH key.
"""
import os
import sys
import json

try:
    import requests
except ImportError:
    print("Error: 'requests' package not installed.")
    print("Install it with: pip3 install requests")
    sys.exit(1)


def main():
    # Read API key
    key_path = os.path.expanduser("~/.vast_api_key")
    if not os.path.exists(key_path):
        print(f"Error: No API key found at {key_path}")
        print("Save your vast.ai API key first:")
        print("  echo 'YOUR_KEY' > ~/.vast_api_key")
        sys.exit(1)

    with open(key_path) as f:
        api_key = f.read().strip()

    # Read SSH public key
    pub_path = os.path.expanduser("~/.ssh/vastai.pub")
    if not os.path.exists(pub_path):
        print(f"Error: No SSH key found at {pub_path}")
        print("Create one with:")
        print('  ssh-keygen -t ed25519 -f ~/.ssh/vastai -N "" -C "vastai-disposable-instances"')
        sys.exit(1)

    with open(pub_path) as f:
        pubkey = f.read().strip()

    # Check if already registered
    print("Checking existing SSH keys on vast.ai...")
    r = requests.get(
        "https://console.vast.ai/api/v0/ssh/",
        params={"api_key": api_key},
    )

    if r.status_code == 401:
        print("Error: API key is invalid or expired.")
        print("Get a new one from https://cloud.vast.ai/cli/")
        sys.exit(1)

    if r.status_code != 200:
        print(f"Error: API returned {r.status_code}: {r.text[:200]}")
        sys.exit(1)

    existing_keys = r.json()
    for k in existing_keys:
        if k.get("public_key", "").strip() == pubkey:
            print("  SSH key is already registered. Nothing to do.")
            return

    # Register the key
    print("  Registering SSH key with vast.ai...")
    r = requests.post(
        "https://console.vast.ai/api/v0/ssh/",
        params={"api_key": api_key},
        json={"ssh_key": pubkey},
    )

    if r.status_code == 200:
        print("  Done! SSH key registered successfully.")
        print(f"  Key: {pubkey[:50]}...")
    else:
        print(f"  Error: {r.status_code}: {r.text[:200]}")
        sys.exit(1)


if __name__ == "__main__":
    main()
