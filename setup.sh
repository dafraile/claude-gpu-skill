#!/bin/bash
# setup.sh — One-command setup for the /gpu Claude Code skill
#
# What this does:
#   1. Creates ~/.claude/commands/ and installs the gpu.md skill
#   2. Creates a dedicated SSH key for vast.ai (no passphrase)
#   3. Prompts for your vast.ai API key and saves it
#   4. Registers the SSH key with your vast.ai account
#
# Usage:
#   bash setup.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=================================="
echo "  /gpu Skill Setup for Claude Code"
echo "=================================="
echo ""

# Step 1: Install the skill
echo "--- Step 1: Installing skill ---"
mkdir -p ~/.claude/commands
cp "$SCRIPT_DIR/gpu.md" ~/.claude/commands/gpu.md
echo "  Installed gpu.md to ~/.claude/commands/"

# Step 2: Create SSH key
echo ""
echo "--- Step 2: SSH key for vast.ai ---"
if [ -f ~/.ssh/vastai ]; then
    echo "  SSH key already exists at ~/.ssh/vastai"
    echo "  Fingerprint: $(ssh-keygen -lf ~/.ssh/vastai.pub)"
else
    echo "  Creating dedicated SSH key (no passphrase)..."
    ssh-keygen -t ed25519 -f ~/.ssh/vastai -N "" -C "vastai-disposable-instances"
    echo "  Created ~/.ssh/vastai (no passphrase)"
fi

# Step 3: API key
echo ""
echo "--- Step 3: Vast.ai API key ---"
if [ -f ~/.vast_api_key ]; then
    echo "  API key already exists at ~/.vast_api_key"
    echo "  (To update, run: echo 'YOUR_NEW_KEY' > ~/.vast_api_key)"
else
    echo "  Get your API key from: https://cloud.vast.ai/cli/"
    echo "  (It's shown under 'Login / Set API Key')"
    echo ""
    read -p "  Paste your vast.ai API key: " api_key
    if [ -n "$api_key" ]; then
        echo "$api_key" > ~/.vast_api_key
        chmod 600 ~/.vast_api_key
        echo "  Saved to ~/.vast_api_key"
    else
        echo "  Skipped. You can set it later:"
        echo "    echo 'YOUR_KEY' > ~/.vast_api_key"
    fi
fi

# Step 4: Register SSH key with vast.ai
echo ""
echo "--- Step 4: Registering SSH key with vast.ai ---"
if [ -f ~/.vast_api_key ]; then
    python3 "$SCRIPT_DIR/register_ssh_key.py"
else
    echo "  Skipped (no API key). Run this after setting your API key:"
    echo "    python3 $SCRIPT_DIR/register_ssh_key.py"
fi

# Done
echo ""
echo "=================================="
echo "  Setup complete!"
echo "=================================="
echo ""
echo "  In any Claude Code session, type:"
echo "    /gpu search tiny      — find cheap GPUs"
echo "    /gpu launch tiny      — rent the cheapest one"
echo "    /gpu status           — check running instances"
echo "    /gpu destroy <id>     — stop charges"
echo ""
echo "  Estimated cost: ~\$0.07/hr for a 12GB GPU (RTX 4070 Ti)"
echo ""
