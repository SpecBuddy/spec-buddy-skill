# SpecBuddy — Claude Code Plugin

**Status:** Draft
**Created:** 2026-04-01
**Last Updated:** 2026-04-01

## Overview

SpecBuddy is a Claude Code plugin that implements a specification-driven development workflow. It enables users to create, refine, and execute technical specifications through a structured pipeline: write a spec, generate an implementation plan from it, execute plan steps one at a time via specialized agents, and iteratively refine both the plan and generated code based on feedback.

The plugin is distributed as a set of markdown-based skills, commands, and agent definitions that extend Claude Code's capabilities.

## Goals

- Provide a complete spec-to-code workflow: spec creation, plan generation, step-by-step execution, and iterative refinement
- Keep the human in the loop at every stage — no automatic progression between steps
- Maintain separation between the plan (the map) and the generated code (the territory), allowing each to be refined independently
- Use plain Markdown as the specification and plan format — no custom DSL or schema
- Detect and report agent hallucinations (claimed work without actual tool usage)

## Non-Goals

- Full implementation of the SpecBuddy product vision (inline markers like `@file:`, `@mcp:`, `@cmd:`, toolchain templates) — those are future work described in `.specs/concept.md`
- IDE-level integrations beyond HTML comment anchors (e.g., `<!-- specbuddy:create-plan -->`)
- Automatic multi-step execution or autonomous plan completion
- Version control or diffing of specifications themselves

---

## Background

AI coding agents work best when given clear, structured instructions. Without a specification, agents produce inconsistent results and require extensive back-and-forth. SpecBuddy addresses this by formalizing the workflow into discrete, reviewable stages.

The broader vision (documented in `.specs/concept.md`) describes a full SpecBuddy tool with inline context markers (`@file:`, `@range:`, `@mcp:`, `@cmd:`, `@spec:`), toolchain templates, and execution graphs. This plugin is an early implementation that focuses on the core loop: spec → plan → execute → refine.

---

## Architecture

### Plugin Structure

The plugin follows the Claude Code plugin convention with three component types:

| Component Type | Location | Trigger | Purpose |
|---|---|---|---|
| **Skills** | `skills/*/SKILL.md` | Auto-invoked by Claude when relevant | Passive capabilities that activate on matching user intent |
| **Commands** | `commands/*.md` | User-invoked via `/spec-buddy:<name>` | Explicit actions with arguments |
| **Agents** | `agents/*.md` | Launched by commands via the Task tool | Specialized sub-agents for focused work |

Plugin metadata lives in `.claude-plugin/plugin.json` (name: `spec-buddy`, current version: `1.0.2`).

### Skills

Two auto-invoked skills provide specification analysis:

1. **spec-analyzer** (`skills/spec-analyzer/SKILL.md`) — Activates when user asks to review, analyze, or check a specification. Performs structure analysis (completeness, organization), content quality checks (clarity, testability, technical accuracy), and flags vague terms, missing error handling, and security gaps. Outputs a categorized report with severity levels (Critical, Important, Minor).

2. **spec-validator** (`skills/spec-validator/SKILL.md`) — Activates when user needs to ensure a spec meets quality standards. Validates requirements against SMART criteria (Specific, Measurable, Achievable, Relevant, Testable), checks documentation standards, technical completeness, and performs risk assessment. Outputs a compliance score with a violation list.

### Commands

Seven user-invoked commands form the core workflow:

1. **`/spec-buddy:new`** (`commands/new.md`) — Creates a new specification document from a user description or prompt. Generates a structured Markdown spec with standard sections (Overview, Goals, Non-Goals, Background, Requirements, Technical Design, Security, Testing, Open Questions). Appends `<!-- specbuddy:create-plan -->` as an IDE action anchor. Saves to a user-specified path or generates a filename under `.specs/`.

2. **`/spec-buddy:edit`** (`commands/edit.md`) — Finalizes a specification after manual user edits. Takes two arguments: the edited spec file and a unified diff of what the user changed. Scans both for inline instructions (TODO markers, natural-language notes, placeholder text) and generates clean spec prose to replace them. Direct text edits by the user are preserved unchanged. Outputs a summary of instructions found and fulfilled.

3. **`/spec-buddy:plan`** (`commands/plan.md`) — Generates an implementation plan from one of three input modes:
   - Plain text description (e.g., "Add user authentication with JWT")
   - Specification reference (`spec:.specs/user-auth.md`)
   - File reference for refactoring (`file:src/legacy/Service.ts`)

   Launches the `plan-generator` agent, which analyzes the codebase and produces a numbered step plan saved to `.specs/plans/<name>.md`. Steps use `### Step N: Title` headings with Context, Actions, and Success Criteria subsections.

4. **`/spec-buddy:execute`** (`commands/execute.md`) — Executes a single step from a plan file. Takes a plan file path and step number. Extracts the step content, finds any spec reference in the plan's References section, and launches the `step-executor` agent with the spec as context and the step as instructions. After execution, validates that the agent actually used tools and created/modified files (hallucination detection). Shows next-step suggestion without auto-executing.

5. **`/spec-buddy:refine-plan`** (`commands/refine-plan.md`) — Updates a plan based on feedback about a previously executed step. Accepts a plan file, step name, optional diff of user's manual code edits, inline per-line comments, and free-form feedback. Launches a general-purpose agent that modifies only the plan file — no source code is touched. Philosophy: "fix the map, not the territory."

6. **`/spec-buddy:refine-generation`** (`commands/refine-generation.md`) — Re-executes a plan step with corrective feedback when the plan is correct but the code output was wrong. Same input format as `refine-plan` (plan file, step name, diff, inline comments, free-form feedback). Launches the `step-executor` agent with the original step plus feedback context. The plan file is explicitly read-only. Philosophy: "the plan is the source of truth."

7. **`/spec-buddy:refine-plan-and-generation`** (`commands/refine-plan-and-generation.md`) — Combines `refine-plan` (Phase 1) and `refine-generation` (Phase 2) sequentially. First updates the plan, then re-reads it and re-executes the affected step with the updated instructions. Both phases receive the same feedback (diff, inline comments, free-form text). Phase 1 changes survive even if Phase 2 fails. Philosophy: "fix the map first, then re-navigate."

### Agents

Two specialized agents handle focused work:

1. **spec-reviewer** (`agents/spec-reviewer.md`) — Reviews specifications in three passes: structure, content, and quality. Focuses on requirement clarity, technical feasibility, security, error handling, edge cases, and API design. Used by the analysis skills.

2. **step-executor** (`agents/step-executor.md`) — Executes exactly one plan step. Reads spec context, reviews referenced files, performs actions, validates all success criteria, and produces a structured report (files changed, commands executed, criteria status). Strictly forbidden from executing multiple steps or suggesting next actions. Used by `execute`, `refine-generation`, and `refine-plan-and-generation` commands.

### Hooks

A `SubagentStop` hook (`hooks/hooks.json`) fires when the `step-executor` agent completes. It launches a lightweight agent that reviews the step-executor's output for context discovered during execution (file structures, API shapes, naming conventions, unexpected findings) and suggests updating subsequent plan steps to reference this context. If no useful context was found, it responds silently.

### Data Flow

```
User prompt
    │
    ▼
/spec-buddy:new  ──►  .specs/<name>.md  (specification)
    │                        │
    │    /spec-buddy:edit  ◄─┘  (user edits spec, agent finalizes)
    │                        │
    ▼                        ▼
/spec-buddy:plan  ──►  .specs/plans/<name>.md  (implementation plan)
    │                        │
    ▼                        ▼
/spec-buddy:execute  ──►  Source code changes  (one step at a time)
    │                        │
    ├── /spec-buddy:refine-plan  ──►  Updates plan only
    ├── /spec-buddy:refine-generation  ──►  Regenerates code only
    └── /spec-buddy:refine-plan-and-generation  ──►  Updates plan, then regenerates
```

---

## File Conventions

| Path | Purpose |
|---|---|
| `.claude-plugin/plugin.json` | Plugin manifest (name, version, author) |
| `skills/*/SKILL.md` | Auto-invoked skill definitions with YAML frontmatter |
| `commands/*.md` | User-invoked command definitions with YAML frontmatter |
| `agents/*.md` | Agent definitions with YAML frontmatter |
| `hooks/hooks.json` | Hook configuration for agent lifecycle events |
| `.specs/*.md` | Specification documents |
| `.specs/plans/*.md` | Implementation plan documents |
| `.snapshots/` | Snapshot history for spec edits and plan executions |
| `CLAUDE.md` | Project-level instructions for Claude Code |

---

## Key Design Decisions

1. **One step at a time** — The user always decides when to proceed to the next step. This prevents runaway execution and ensures quality review at each stage.

2. **Plan vs. code separation** — Three distinct refinement commands (`refine-plan`, `refine-generation`, `refine-plan-and-generation`) reflect the principle that the plan and the code are independent artifacts. The plan can be correct while the code is wrong, or vice versa.

3. **Hallucination detection** — After every agent execution, the command validates that the agent actually used tools and that reported files exist. This catches a known failure mode where agents claim completion without performing work.

4. **Diff-as-context pattern** — Refinement commands accept a diff of the user's manual code edits. The diff is passed to agents as evidence of dissatisfaction, not as changes to apply mechanically. The user may have already committed, reverted, or further modified those changes.

5. **Hooks for cross-step context** — The `SubagentStop` hook automatically captures context discovered during step execution and suggests propagating it to subsequent steps, preventing information loss between steps.

6. **Markdown-only format** — Both specifications and plans are plain Markdown files with no custom frontmatter, DSL, or schema beyond standard headings and lists. This keeps them human-readable and editable without tooling.

---

## Security Considerations

- Agent tools are restricted per agent type — `step-executor` has file read/write and bash but agents should only operate within the project scope
- The `@cmd:` marker (from the future vision) specifies that commands must be in an allowlist — not yet implemented
- No authentication or network access patterns are part of the current plugin
- Diff files and inline comments are treated as untrusted user input — agents are instructed not to apply them mechanically

---

## Testing Strategy

- Manual testing via `claude --plugin-dir /path/to/spec-buddy-skill` after any changes
- A test project exists at `.test/` (Spring Boot Java app) used for testing plan execution against real code
- Validation of agent behavior relies on hallucination detection (tool usage checks, file existence verification)
- Snapshot history in `.snapshots/` provides before/after records for spec edits

---

## Open Questions

- How should the plugin handle spec versioning and change history beyond snapshots?
- Should plan steps support parallel execution for independent tasks?
- How to integrate the future `@file:`, `@range:`, `@mcp:`, `@cmd:`, `@spec:` inline markers from the concept doc?
- Should the plugin provide toolchain templates and example specs as described in the product vision?
- How to handle long-running agent steps that exceed context window limits?

---

## References

- `.specs/concept.md` — Full SpecBuddy product vision and concept document
- `CLAUDE.md` — Project-level Claude Code instructions
- `.claude-plugin/plugin.json` — Plugin manifest

<!-- specbuddy:create-plan  -->
