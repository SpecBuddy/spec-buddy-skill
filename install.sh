#!/usr/bin/env bash

set -e

_PATH=$($SHELL -l -c 'echo $PATH' 2>/dev/null || echo "")
if [ -n "$_PATH" ]; then
  export PATH="$_PATH"
fi

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"


REPO_URL="https://github.com/SpecBuddy/spec-buddy-skill.git"
REPO_BASE_DIR="$HOME/.agents"
REPO_DIR="$REPO_BASE_DIR/.spec-buddy/spec-buddy-skill"
LOCAL_DIR="$(pwd)"
AGENTS_SKILLS_DIR="$LOCAL_DIR/.agents/skills"
QWEN_SKILLS_DIR="$LOCAL_DIR/.qwen/skills"

echo "== Spec Buddy Skills Installer =="

mkdir -p "$REPO_BASE_DIR/.spec-buddy"
mkdir -p "$AGENTS_SKILLS_DIR"

# --- Git sync ---
if [ -d "$REPO_DIR/.git" ]; then
  echo "✔ Repo exists, pulling latest..."
  git -C "$REPO_DIR" pull
else
  echo "⬇ Cloning repository..."
  git clone "$REPO_URL" "$REPO_DIR"
fi

# --- Symlinks to ~/.agents/skills/ (Codex, OpenCode, Gemini CLI, KiloCode) ---
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

# --- Qwen Code: symlinks to ~/.qwen/skills/ ---
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

# --- Claude Code: marketplace plugin ---
if command -v claude >/dev/null 2>&1; then
  echo "🤖 Claude Code found, installing plugin..."

  claude plugin marketplace add "$REPO_URL" --scope local || true
  claude plugin install spec-buddy@spec-buddy-repo --scope local || true
  claude plugin update spec-buddy@spec-buddy-repo --scope local || true

  echo "✅ Claude Code plugin ready"
else
  echo "⚠ Claude CLI not found, skipping Claude Code setup"
fi

echo "🎉 Done"
