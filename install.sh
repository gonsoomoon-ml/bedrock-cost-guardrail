#!/usr/bin/env bash
# install.sh — One-command installer for bedrock-cost-guardrail plugin
set -euo pipefail

REPO_URL="https://github.com/cost-guardrail-team/bedrock-cost-guardrail.git"
INSTALL_DIR="$HOME/.claude/plugins/bedrock-cost-guardrail"
PLUGIN_PATH="$INSTALL_DIR/plugins/bedrock-cost-guardrail"
SETTINGS_FILE="$HOME/.claude/settings.json"

log() { echo "[bedrock-cost-guardrail] $1"; }
err() { echo "[bedrock-cost-guardrail] ERROR: $1" >&2; exit 1; }

# --- Step 1: Check prerequisites ---
log "Checking prerequisites..."
MISSING=""
for cmd in claude jq aws bc git; do
  if ! command -v "$cmd" &>/dev/null; then
    MISSING="$MISSING $cmd"
  fi
done
if [[ -n "$MISSING" ]]; then
  err "Missing required commands:$MISSING"
fi

# --- Step 2: Clone or update ---
if [[ -d "$INSTALL_DIR" ]]; then
  log "Updating existing installation..."
  git -C "$INSTALL_DIR" pull --quiet || err "Failed to update $INSTALL_DIR"
else
  log "Cloning to $INSTALL_DIR..."
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --quiet "$REPO_URL" "$INSTALL_DIR" || err "Failed to clone $REPO_URL"
fi

# --- Step 3: Register marketplace ---
log "Registering marketplace..."
claude plugin marketplace add "$INSTALL_DIR" || err "Failed to register marketplace"

# --- Step 4: Install plugin ---
log "Installing plugin..."
claude plugin install bedrock-cost-guardrail@bedrock-cost-guardrail || err "Failed to install plugin"

# --- Step 5: Patch settings.json ---
log "Configuring settings.json hooks..."
HOOK_SS="bash $PLUGIN_PATH/hooks/check-cost.sh --event session_start"
HOOK_PS="bash $PLUGIN_PATH/hooks/check-cost.sh --event prompt_submit"

mkdir -p "$(dirname "$SETTINGS_FILE")"

SS_HOOK='{"hooks": [{"type": "command", "command": "'"$HOOK_SS"'", "timeout": 60}]}'
PS_HOOK='{"hooks": [{"type": "command", "command": "'"$HOOK_PS"'", "timeout": 30}]}'

if [[ ! -f "$SETTINGS_FILE" ]]; then
  # Create new settings.json with hooks
  jq -n \
    --argjson ss "$SS_HOOK" \
    --argjson ps "$PS_HOOK" \
    '{
      hooks: {
        SessionStart: [$ss],
        UserPromptSubmit: [$ps]
      }
    }' > "$SETTINGS_FILE" || err "Failed to create $SETTINGS_FILE"
else
  # Merge hooks into existing settings.json, preserving other plugins' hooks
  TEMP_FILE="$(mktemp)"
  jq \
    --argjson ss "$SS_HOOK" \
    --argjson ps "$PS_HOOK" \
    --arg marker "check-cost.sh" \
    '
    # Remove any existing cost-guardrail hooks (by matching command string)
    .hooks.SessionStart = ([(.hooks.SessionStart // [])[] | select(.hooks[0].command | contains($marker) | not)] + [$ss])
    | .hooks.UserPromptSubmit = ([(.hooks.UserPromptSubmit // [])[] | select(.hooks[0].command | contains($marker) | not)] + [$ps])
    ' \
    "$SETTINGS_FILE" > "$TEMP_FILE" || err "Failed to patch $SETTINGS_FILE. Manual setup required — see README."
  mv "$TEMP_FILE" "$SETTINGS_FILE"
fi

# --- Done ---
log "Done! Plugin installed successfully."
echo ""
echo "  Verify: /bedrock-cost-guardrail:cost-status"
echo "  Config: /bedrock-cost-guardrail:cost-config show"
