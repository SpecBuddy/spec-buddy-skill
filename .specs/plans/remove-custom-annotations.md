# Remove Custom Annotations from Spec Format

**Status:** Draft
**Created:** 2026-03-11
**Last Updated:** 2026-03-11

## Overview

Remove all custom SpecBuddy annotations (`@step:start`/`@step:end`, `@file:`, `@range:`, `@cmd:`, `@mcp:`, `@spec:`) from the plugin codebase. Replace the structured annotation-based step format with plain markdown that Claude can interpret naturally.

## Goals

- Remove `@step:start`/`@step:end` boundary markers from all spec and plan files
- Remove or replace `@file:`, `@range:`, `@cmd:`, `@mcp:`, `@spec:` inline markers (the `#Lx-y` line range notation is kept in plain file references)
- Update CLAUDE.md so it no longer documents this annotation syntax
- Update command and agent instructions to not reference or expect annotation syntax
- Keep specs readable and actionable without custom syntax

## Non-Goals

- Changing the overall spec structure (Overview, Goals, Steps, Criteria sections)
- Rewriting spec content — only strip/replace the annotation markers
- Modifying the `.snapshots/` historical files
- Modifying `.specs/plans/` files — these are development history and are left as-is

---

## Background

The custom annotation format was designed as a machine-parsable layer over plain markdown — allowing agents to extract context files, run commands, and bound steps deterministically. In practice, Claude interprets markdown context naturally, so the custom markers add noise without meaningful benefit for the current plugin architecture.

## Affected Files

### Core documentation (high priority)
- `CLAUDE.md` — defines annotation syntax, must be updated first
- `.specs/concept.md` — original concept document describing the format

### Commands
- `commands/new.md` — shows example step structure with annotations
- `commands/plan.md` — documents all annotation types
- `commands/execute.md` — references `@step` parsing

### Agents
- `agents/step-executor.md` — built around `@step` extraction
- `agents/plan-generator.md` — generates plans with annotation markers

### Specification files
- `.specs/spec-creation-command.md`
- `.specs/spec-editor.md`
- `.specs/plan-execution-command.md`
- `.specs/implementation-plan-command.md`

---

## Implementation Steps

### Step 1: Update CLAUDE.md

Remove the annotation syntax definitions and examples from `CLAUDE.md`. Replace references to `@step`, `@file`, `@range`, `@cmd`, `@mcp`, `@spec` with plain-language descriptions of how to write specs.

**Files:** `CLAUDE.md`

**Success Criteria:**
- [ ] No `@step`, `@file`, `@range`, `@cmd`, `@mcp`, `@spec` syntax documented in CLAUDE.md
- [ ] Spec format section describes plain markdown steps instead

### Step 2: Update command files

Remove annotation examples from command instructions. Commands should describe the plain markdown step format instead of annotation-based format.

**Files:** `commands/new.md`, `commands/plan.md`, `commands/execute.md`

**Success Criteria:**
- [ ] `commands/new.md` shows plain markdown step template without `@step` markers
- [ ] `commands/plan.md` no longer lists annotation types
- [ ] `commands/execute.md` does not instruct agent to parse `@step` boundaries

### Step 3: Update agent instructions

Rewrite `agents/step-executor.md` and `agents/plan-generator.md` to work with plain markdown steps instead of annotated steps.

**Files:** `agents/step-executor.md`, `agents/plan-generator.md`

**Success Criteria:**
- [ ] `step-executor` agent identifies steps from markdown headings/numbering, not `@step` markers
- [ ] `plan-generator` agent produces plans without `@step` annotations

### Step 4: Clean up spec and plan files

Strip `@step:start`/`@step:end` wrappers and replace inline `@file:`, `@cmd:` etc. markers with plain prose equivalents in all `.specs/` files.

For example:
- `@cmd:mvn clean test` → list item: `Run: \`mvn clean test\``
- `@file:path/to/file` → `See \`path/to/file\``
- `@range:path#L10-L42` → `See \`path/to/file#L10-L42\`` (keep the `#Lx-y` line range notation, drop the `@range:` prefix)

**Files:** all `.specs/*.md` spec files (plan files in `.specs/plans/` are excluded — kept as development history)

**Success Criteria:**
- [ ] No `@step:start`/`@step:end` markers remain in `.specs/*.md`
- [ ] No `@file:`, `@range:`, `@cmd:`, `@mcp:`, `@spec:` markers remain in `.specs/*.md` (bare `#Lx-y` line range notation is permitted)
- [ ] Steps are still clearly delineated by markdown headings

---

## Open Questions

- Should `commands/execute.md` be simplified or removed entirely once `@step` parsing is gone?
- Is there a replacement convention for marking "run this command" steps that stays readable without custom markers (e.g., a `**Run:**` bold label)?

## References

- Current annotation definitions: `CLAUDE.md` (Spec format section)
- Original concept: `.specs/concept.md`
