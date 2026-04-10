# /gpu — Claude Code Skill for Vast.ai GPU Management

A [Claude Code](https://claude.ai/claude-code) slash command that lets you rent, manage, and tear down GPU instances on [vast.ai](https://vast.ai) without leaving your terminal.

Type `/gpu launch tiny` and Claude handles the rest — finds the cheapest GPU, spins it up, uploads your project files, installs dependencies, and gives you SSH access. When you're done, `/gpu destroy` pulls your results and kills the instance so charges stop.

## Why

If you're doing ML research with Claude Code, you often need a GPU for a few hours — run an experiment, pull results, destroy. The friction is in the setup: searching for offers, configuring SSH, installing deps, remembering to destroy when done. This skill eliminates all of that.

## Demo

```
You: /gpu launch tiny
Claude: Searching for cheapest 10GB+ GPU...
        Found: RTX 4070 Ti, 12GB, $0.067/hr (offer 33675033)
        Launching... booting... ready!
        Uploading project files... installing deps... done.
        SSH: ssh -i ~/.ssh/vastai -p 27160 root@ssh8.vast.ai

You: /gpu ssh
Claude: Connecting to instance 34507160...
        root@C.34507160:/workspace$ python3 my_experiment.py

You: /gpu pull
Claude: Downloading results/ and cached files...

You: /gpu destroy
Claude: Have you pulled all data? [confirmed]
        Instance destroyed. No more charges.
```

## Setup

### 1. Install the skill

Copy `gpu.md` to your Claude Code global commands directory:

```bash
# Clone this repo
git clone https://github.com/dafraile/claude-gpu-skill.git
cd claude-gpu-skill

# Run the setup script (creates SSH key, configures vast.ai API)
bash setup.sh
```

Or manually:
```bash
mkdir -p ~/.claude/commands
cp gpu.md ~/.claude/commands/gpu.md
```

### 2. Get your vast.ai API key

1. Create an account at [vast.ai](https://cloud.vast.ai/)
2. Go to https://cloud.vast.ai/cli/
3. Copy the API key shown under "Login / Set API Key"
4. Save it:

```bash
echo "YOUR_API_KEY_HERE" > ~/.vast_api_key
chmod 600 ~/.vast_api_key
```

### 3. Create a dedicated SSH key (no passphrase)

The setup script does this automatically, but if you want to do it manually:

```bash
# Create a passwordless key just for vast.ai
ssh-keygen -t ed25519 -f ~/.ssh/vastai -N "" -C "vastai-disposable-instances"

# Register it with vast.ai
python3 register_ssh_key.py
```

This key has no passphrase because:
- It's only used for disposable GPU instances (not your servers or GitHub)
- Claude Code needs to SSH non-interactively (it can't type passphrases)
- If compromised, an attacker gets access to your rented GPU for the few hours it exists — not your real infrastructure

### 4. (Optional) HuggingFace token

If you work with gated models (Gemma, Llama, Mistral), log into HuggingFace so the token is available:

```bash
pip install huggingface-hub
huggingface-cli login
```

The skill automatically copies `~/.cache/huggingface/token` to each new instance.

## Commands

| Command | Description |
|---------|-------------|
| `/gpu search [profile]` | Find available GPU offers matching a profile |
| `/gpu launch [profile]` | Launch the cheapest matching instance |
| `/gpu status` | List running instances |
| `/gpu setup [id]` | Upload project files and install deps |
| `/gpu ssh [id]` | Get SSH command for an instance |
| `/gpu pull [id]` | Download results from instance |
| `/gpu destroy [id]` | Destroy instance (stops all charges) |
| `/gpu run [profile] [script]` | All-in-one: launch, setup, run, pull, destroy |

## GPU Profiles

Pick the smallest that fits your task. Don't rent an H100 for a 1B model.

| Profile | Min VRAM | Good for | Typical cost |
|---------|----------|----------|-------------|
| `tiny` | 10 GB | 1-3B models, inference, small SAEs | $0.05-0.15/hr |
| `medium` | 22 GB | 4-7B models, fine-tuning, SAE training | $0.20-0.40/hr |
| `large` | 45 GB | 13B models, large-scale analysis | $0.50-1.00/hr |
| `huge` | 80 GB | 70B+ models, multi-GPU | $1.50-4.00/hr |

## How it works

The skill uses the [vast.ai REST API](https://docs.vast.ai/api/overview-and-quickstart) directly — no CLI tool needed (the official `vastai` pip package requires Python 3.10+ which not all systems have).

```
/gpu launch tiny
    │
    ├── 1. Search API: find cheapest offer with ≥10GB VRAM, CUDA ≥12, reliability ≥0.95
    ├── 2. Create API: rent the instance with PyTorch Docker image
    ├── 3. Poll API: wait for status == "running" (usually 30-90 seconds)
    ├── 4. SSH: upload project files, copy HF token, install deps
    └── 5. Report: SSH command ready for use
```

All SSH uses `~/.ssh/vastai` (dedicated passwordless key). All API calls use `~/.vast_api_key`.

## File structure

```
claude-gpu-skill/
├── gpu.md                  # The skill file (copy to ~/.claude/commands/)
├── setup.sh                # One-command setup: SSH key + API key + install
├── register_ssh_key.py     # Register SSH key with vast.ai account
└── README.md               # This file
```

## Troubleshooting

**SSH "Permission denied"**: The instance may still be booting. Wait 10 seconds and retry. If persistent, check that `~/.ssh/vastai` exists and is registered with vast.ai (run `python3 register_ssh_key.py`).

**API "401 Unauthorized"**: Your API key expired. Get a new one from https://cloud.vast.ai/cli/ and save to `~/.vast_api_key`.

**torchvision errors**: The default PyTorch Docker image bundles torchvision which can conflict with transformer-lens/SAELens. The skill automatically runs `pip uninstall -y torchvision` during setup.

**"No offers found"**: The GPU market fluctuates. Try a different profile or wait a few minutes. You can also relax reliability with `/gpu search tiny` and manually pick from the results.

## Cost tips

- A `tiny` instance (RTX 4070 Ti) costs ~$0.07/hr. A 3-hour experiment costs $0.21.
- **Always destroy when done.** Even stopped instances accrue storage charges (~$0.10/GB/month).
- Use `/gpu run` for fire-and-forget experiments — it auto-destroys after pulling results.
- Spot/interruptible instances are even cheaper but can be terminated mid-run.

## License

MIT
