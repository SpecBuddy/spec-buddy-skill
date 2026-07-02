#!/usr/bin/env bash

set -e

_PATH=$($SHELL -l -c 'echo $PATH' 2>/dev/null || echo "")
if [ -n "$_PATH" ]; then
  export PATH="$_PATH"
fi

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"


# Source = this local checkout (the directory this script lives in).
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Target = the project you run this script from.
LOCAL_DIR="$(pwd)"
AGENTS_SKILLS_DIR="$LOCAL_DIR/.agents/skills"
QWEN_SKILLS_DIR="$LOCAL_DIR/.qwen/skills"

echo "== Spec Buddy Skills Local Installer =="
echo "📁 Source: $REPO_DIR"
echo "📂 Target: $LOCAL_DIR"

if [ ! -d "$REPO_DIR/skills" ]; then
  echo "❌ Error: '$REPO_DIR/skills' not found. This script must live inside the spec-buddy-skill repository."
  exit 1
fi

mkdir -p "$AGENTS_SKILLS_DIR"

# --- Symlinks to .agents/skills/ (Codex, OpenCode, Gemini CLI, KiloCode) ---
echo "🔗 Creating/updating symlinks in .agents/skills/ (local)..."

for skill_path in "$REPO_DIR/skills/"*; do
  [ -d "$skill_path" ] || continue
  skill_name=$(basename "$skill_path")
  target_link="$AGENTS_SKILLS_DIR/$skill_name"

  if [ -L "$target_link" ] || [ -e "$target_link" ]; then
    rm -rf "$target_link"
  fi

  ln -s "$skill_path" "$target_link"
  echo "  ✔ $skill_name"
done

echo "✅ Skills ready (Codex, OpenCode, Gemini CLI, KiloCode)"

# --- Qwen Code: symlinks to .qwen/skills/ ---
if [ -d "$HOME/.qwen" ] || command -v qwen >/dev/null 2>&1; then
  echo "🔗 Creating/updating symlinks in .qwen/skills/ (local)..."
  mkdir -p "$QWEN_SKILLS_DIR"

  for skill_path in "$REPO_DIR/skills/"*; do
    [ -d "$skill_path" ] || continue
    skill_name=$(basename "$skill_path")
    target_link="$QWEN_SKILLS_DIR/$skill_name"

    if [ -L "$target_link" ] || [ -e "$target_link" ]; then
      rm -rf "$target_link"
    fi

    ln -s "$skill_path" "$target_link"
    echo "  ✔ $skill_name"
  done

  echo "✅ Qwen Code skills ready"
fi

# --- Claude Code: marketplace plugin from local path ---
if command -v claude >/dev/null 2>&1; then
  echo "🤖 Claude Code found, installing plugin from local repo..."

  claude plugin marketplace add "$REPO_DIR" --scope local || true
  claude plugin install spec-buddy@spec-buddy-repo --scope local || true
  claude plugin update spec-buddy@spec-buddy-repo --scope local || true

  echo "✅ Claude Code plugin ready"
else
  echo "⚠ Claude CLI not found, skipping Claude Code setup"
fi

echo "🎉 Done"
