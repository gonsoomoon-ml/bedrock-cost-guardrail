# Bedrock Cost Guardrail

Claude Code plugin that monitors per-IAM-user Amazon Bedrock API costs and blocks usage when a spending threshold is reached.

## Install

    curl -sSL https://raw.githubusercontent.com/gonsoomoon-ml/bedrock-cost-guardrail/main/install.sh | bash

Or clone and run manually:

    git clone https://github.com/gonsoomoon-ml/bedrock-cost-guardrail.git ~/.claude/plugins/bedrock-cost-guardrail
    bash ~/.claude/plugins/bedrock-cost-guardrail/install.sh

## Prerequisites

- [Claude Code](https://claude.ai/code) installed
- AWS CLI v2 configured with permissions: `logs:StartQuery`, `logs:GetQueryResults`, `sts:GetCallerIdentity`
- Bedrock Model Invocation Logging enabled (CloudWatch Logs)
- jq, bc installed

## Usage

### Check current cost

    /bedrock-cost-guardrail:cost-status

### View or change settings

    /bedrock-cost-guardrail:cost-config show
    /bedrock-cost-guardrail:cost-config set check_interval 5
    /bedrock-cost-guardrail:cost-config set period daily

## How It Works

- Checks estimated Bedrock cost at session start and every Nth prompt (default: 10)
- Calculates cost from CloudWatch Logs using per-model token pricing (input, output, cache read, cache write)
- Blocks usage (hard block) when the configured spending threshold is reached
- Fails open on all errors — infrastructure issues never block developers

## Default Settings

| Setting | Default | Description |
|---------|---------|-------------|
| threshold_usd | $50 | Spending limit before blocking |
| period | monthly | Cost accumulation window |
| check_interval | 10 | Check cost every Nth prompt |
| timezone | UTC | Period boundary timezone |

## Uninstall

1. Remove hooks from `~/.claude/settings.json` (delete the `SessionStart` and `UserPromptSubmit` entries referencing `check-cost.sh`)
2. Uninstall plugin: `claude plugin uninstall bedrock-cost-guardrail` (if supported)
3. Remove marketplace: `claude plugin marketplace remove bedrock-cost-guardrail` (if supported)
4. Remove the plugin directory: `rm -rf ~/.claude/plugins/bedrock-cost-guardrail`

## Source

Development repo and detailed documentation: [cost-guardrail-claude-code-bedrock](https://github.com/gonsoomoon-ml/cost-guardrail-claude-code-bedrock)
