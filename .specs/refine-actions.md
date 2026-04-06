# Refine Actions: refine-plan, refine-generation & refine-plan-and-generation Commands

**Status:** Draft
**Created:** 2026-03-16
**Last Updated:** 2026-03-16

## Overview

Three commands for refining plans and code after a step has been executed. All three share a common input format: a path to a diff file, plus a structured multi-line body with optional inline file comments and free-form feedback text.

## Goals

- Allow iterative refinement of plans and code after execution
- Propagate user feedback into the plan only (refine-plan)
- Propagate user feedback into code only, without changing the plan (refine-generation)
- Propagate user feedback into both the plan and the codebase (refine-plan-and-generation)
- Keep the feedback loop tight: execute → review → refine → continue

## Non-Goals

- Automatic execution of the next step (user still controls advancement)
- Rollback of already-executed steps (no undo)
- Applying the diff automatically — the diff file is passed as context for the agent to read and reason about, not to be applied mechanically

## Background

After `/spec-buddy:execute plan.md <step>` runs a step, the user reviews the result. They may want to:
- **Adjust only the plan** (e.g., the approach is wrong, future steps need rewording): use `refine-plan`
- **Fix only the generated code** (e.g., the plan is fine but the output code has a bug): use `refine-generation`
- **Fix the generated code AND update the plan** (e.g., both the plan reasoning and the code output are wrong): use `refine-plan-and-generation`

The user provides feedback using a structured format:

```
/<command> <plan-file> <step-name> <userDiffPath>
### Inline comments
- <filePath>:<lineNumber>: <comment>

Free form feedback
```

- **`<userDiffPath>`** — path to a diff file capturing the manual edits the user made to the generated code after the previous agent execution (e.g., saved with `git diff > my.diff`), or an empty string if no diff. The agent reads this diff as evidence of what the user was dissatisfied with — not as changes to apply mechanically. The edits it records may already be in place in the working tree, or may have been reverted before this command runs.
- **`### Inline comments`** — optional section listing per-line comments in the form `<filePath>:<lineNumber>: <comment>`
- **Free form feedback** — plain-text explanation of what is wrong and what should change instead

The agent reads the diff file and all comments as context — it does not apply the diff mechanically.

## User Workflow

```
1. /spec-buddy:execute plan.md 1                    → Execute step
2. Review results, save diff: git diff > my.diff
3a. /spec-buddy:refine-plan plan.md "Step 1: Setup" my.diff
    ### Inline comments
    - src/auth.ts:42: wrong constant name
                                                     → Plan edited, no code touched
   OR
3b. /spec-buddy:refine-generation plan.md "Step 1: Setup" my.diff
    Free form feedback here
                                                     → Code regenerated, plan unchanged
   OR
3c. /spec-buddy:refine-plan-and-generation plan.md "Step 1: Setup" my.diff
    ### Inline comments
    - src/auth.ts:42: wrong constant name

    Also fix the return type
                                                     → Plan edited AND code regenerated
4. /spec-buddy:execute plan.md 2                    → Continue with next step
```

---

## Command 1: refine-plan

### Description

Accepts a plan file path and user feedback (diff + comments). Edits the plan to reflect the feedback. Does **not** touch any implementation code.

### Invocation

```
/spec-buddy:refine-plan <plan-file> <step-name> <userDiffPath>
### Inline comments
- <filePath>:<lineNumber>: <comment>

Free form feedback
```

**Arguments:**
- `<plan-file>`: Path to the implementation plan markdown file
- `<step-name>`: Quoted name of the step that was just executed (e.g., `"Step 2: Hash Password"`)
- `<userDiffPath>`: Path to a diff file containing the user's manual edits to the generated code after the previous execution, or empty string if no diff. Read as a signal of what went wrong — not applied mechanically.
- **Multi-line body** (optional): structured block after the first line, containing:
  - `### Inline comments` section — per-line comments as `<filePath>:<lineNumber>: <comment>`
  - Free-form feedback text below

**Example:**
```
/spec-buddy:refine-plan .specs/plans/add-auth.md "Step 2: Hash Password" ./my.diff
### Inline comments
- src/auth/hash.ts:12: bcrypt rounds should be 6, not 12

Add a step for input validation before hashing.
```

### Requirements

#### FR1: Parse Arguments
- Extract `<plan-file>`, `<step-name>`, and `<userDiffPath>` from the first line of `$ARGUMENTS`
- Extract the multi-line body (everything after the first line) as feedback context, which may include an `### Inline comments` section and free-form text
- If required arguments missing: show usage and stop

#### FR2: Read Plan and Diff Files
- Use Read tool to load plan file; show error if not found
- If `<userDiffPath>` is provided and non-empty, use Read tool to load the diff file; warn if not found but continue

#### FR3: Apply Feedback to Plan
- Launch a general-purpose agent via Task tool
- Pass: plan content + step name + diff content (if any) + inline comments + free-form feedback
- Agent responsibilities:
  - Understand which step is being discussed (step name provides context)
  - Use the diff and comments to understand what went wrong
  - Edit the plan file to reflect the requested changes
  - May rewrite existing steps, add new steps, or remove steps
  - Must preserve plan structure and formatting conventions

#### FR4: Report Changes
- Show a summary of what was changed in the plan
- Indicate which steps were added / modified / removed

### Agent Prompt Template

```markdown
You are refining an implementation plan based on user feedback about a specific step.

## Current Plan

@file:<plan-file>

## Context

The user just executed step "<step-name>" and has feedback about it.

## Diff (manual edits the user made after the previous execution)

This diff captures changes the user applied to the generated code after the last agent run.
Use it to understand what the user was dissatisfied with. Do NOT re-apply these changes —
they may already be in place, or may have been reverted before this command runs.

<if userDiffPath provided: @file:<userDiffPath>>
<if no diff: (no diff provided)>

## Inline Comments

<paste inline comments here, e.g.:
- src/auth/hash.ts:12: bcrypt rounds should be 6, not 12>
<if none: (no inline comments)>

## Free-form Feedback

<paste free-form feedback text here>
<if none: (no additional feedback)>

## Task

1. Read the plan carefully
2. Read the diff and comments to understand what went wrong in the implementation
3. Edit the plan file (using the Edit or Write tool) to apply the requested changes:
   - Rewrite steps that need changing
   - Add new steps if requested
   - Remove steps if requested
   - Preserve overall structure and markdown formatting
4. Report a brief summary of the changes you made

Rules:
- Do NOT touch any source code files
- Only modify the plan file itself
- If the feedback is ambiguous, apply the most reasonable interpretation and note your assumption
```

---

## Command 2: refine-plan-and-generation

### Description

Accepts a plan file path and user feedback (diff + comments). First updates the plan, then re-executes the affected step(s) using the updated plan. This rewrites the implementation code for those steps.

### Invocation

```
/spec-buddy:refine-plan-and-generation <plan-file> <step-name> <userDiffPath>
### Inline comments
- <filePath>:<lineNumber>: <comment>

Free form feedback
```

**Arguments:**
- `<plan-file>`: Path to the implementation plan markdown file
- `<step-name>`: Quoted name of the step to re-execute after refining (e.g., `"Step 2: Hash Password"`)
- `<userDiffPath>`: Path to a diff file containing the user's manual edits to the generated code after the previous execution, or empty string if no diff. Read as a signal of what went wrong — not applied mechanically.
- **Multi-line body** (optional): `### Inline comments` section and free-form feedback text

**Example:**
```
/spec-buddy:refine-plan-and-generation .specs/plans/add-auth.md "Step 2: Hash Password" ./my.diff
### Inline comments
- src/auth/hash.ts:8: function should be async

The password hashing function should use await hash() instead of hashSync().
```

### Requirements

#### FR1: Parse Arguments
- Extract `<plan-file>`, `<step-name>`, and `<userDiffPath>` from the first line of `$ARGUMENTS`
- Extract the multi-line body as feedback context (inline comments + free-form text)
- If required arguments missing: show usage and stop

#### FR2: Read Plan and Diff Files
- Use Read tool to load plan file; show error if not found
- If `<userDiffPath>` is provided, read the diff file; warn if not found but continue

#### FR3: Refine Plan
- Same as `refine-plan` FR3: launch agent to update the plan based on feedback
- Wait for completion before proceeding

#### FR4: Re-execute Affected Step
- After plan is updated, re-run the specified step using the same mechanism as `/spec-buddy:execute`
- Launch `step-executor` agent with:
  - Updated plan content
  - Spec file reference (from plan's References section, if present)
  - The updated step section
  - Feedback context so the agent knows what to fix
- Agent must regenerate/fix the implementation for that step

#### FR5: Report Results
- Show what changed in the plan
- Show what the re-execution agent did
- Suggest next step if current step is not the last

### Agent Prompt Templates

**Phase 1 — Plan Refinement** (same as refine-plan):
```markdown
You are refining an implementation plan based on user feedback about a specific step.

## Current Plan

@file:<plan-file>

## Context

The user just executed step "<step-name>" and has feedback about it.

## Diff (manual edits the user made after the previous execution)

This diff captures changes the user applied to the generated code after the last agent run.
Use it to understand what the user was dissatisfied with. Do NOT re-apply these changes —
they may already be in place, or may have been reverted before this command runs.

<if userDiffPath provided: @file:<userDiffPath>>
<if no diff: (no diff provided)>

## Inline Comments

<paste inline comments here>
<if none: (no inline comments)>

## Free-form Feedback

<paste free-form feedback text here>
<if none: (no additional feedback)>

## Task

Edit the plan file to reflect the feedback. Only modify the plan — do not touch source code.
Report briefly what you changed.
```

**Phase 2 — Step Re-execution:**
```markdown
You are re-executing a plan step after the plan was just refined.

🎯 CRITICAL: Execute ONLY the step shown below. Do NOT execute other steps.

## Diff (manual edits the user made after the previous execution)

This diff captures changes the user applied to the generated code after the last agent run.
Use it to understand what the user was dissatisfied with. Do NOT re-apply these changes —
they may already be in place, or may have been reverted before this command runs.

<if userDiffPath provided: @file:<userDiffPath>>
<if no diff: (no diff provided)>

## Inline Comments

<paste inline comments here>
<if none: (no inline comments)>

## Free-form Feedback

<paste free-form feedback text here>
<if none: (no additional feedback)>

## Specification Context

<if spec file reference found: @file:<spec-path>>

## Step to Execute (from updated plan)

<paste the updated step section here>

---

Execute this step now:
1. Read any @file: references above for context
2. Use the diff, inline comments, and feedback to understand what was wrong previously
3. Perform the actions listed in the step, correcting the issues described
4. Validate ALL success criteria
5. Report your results

Remember: Execute THIS step ONLY. Do not proceed to other steps.
```

---

## Command 3: refine-generation

### Description

Accepts a plan file path, step number, and user feedback (diff + comments). Re-executes the specified step with the feedback as corrective context. Does **not** modify the plan — only the code produced by the step is regenerated.

Use this when the plan itself is correct but the code output was wrong (a bug, wrong approach in implementation, missed requirement in the generated code).

### Invocation

```
/spec-buddy:refine-generation <plan-file> <step-name> <userDiffPath>
### Inline comments
- <filePath>:<lineNumber>: <comment>

Free form feedback
```

**Arguments:**
- `<plan-file>`: Path to the implementation plan markdown file
- `<step-name>`: Quoted name of the step to re-execute (e.g., `"Step 2: Hash Password"`)
- `<userDiffPath>`: Path to a diff file containing the user's manual edits to the generated code after the previous execution, or empty string if no diff. Read as a signal of what went wrong — not applied mechanically.
- **Multi-line body** (optional): `### Inline comments` section and free-form feedback text

**Example:**
```
/spec-buddy:refine-generation .specs/plans/add-auth.md "Step 2: Hash Password" ./my.diff
### Inline comments
- src/auth/hash.ts:8: must be async

The hash function must use await hash() instead of hashSync().
```

### Requirements

#### FR1: Parse Arguments
- Extract `<plan-file>`, `<step-name>`, and `<userDiffPath>` from the first line of `$ARGUMENTS`
- Extract the multi-line body as feedback context (inline comments + free-form text)
- If required arguments missing: show usage and stop

#### FR2: Read Plan and Diff Files
- Use Read tool to load plan file; show error if not found
- If `<userDiffPath>` is provided, read the diff file; warn if not found but continue

#### FR3: Extract Step and Re-execute
- Find the step heading in the plan whose title matches `<step-name>` (case-insensitive)
- If step not found: list all available step headings and stop
- Launch `step-executor` agent with:
  - Spec file reference (from plan's References section, if present)
  - The step section (unchanged — plan is not modified)
  - Feedback context so the agent knows what to fix
- Agent must regenerate/fix the implementation, correcting the issues described

#### FR4: Report Results
- Show what the re-execution agent did
- Confirm no plan changes were made
- Suggest next step if current step is not the last

### Agent Prompt Template

```markdown
You are re-executing a plan step to fix an issue in the previously generated code.

🎯 CRITICAL: Execute ONLY the step shown below. Do NOT execute other steps.
   The plan file must NOT be modified — only fix the implementation code.

## Diff (manual edits the user made after the previous execution)

This diff captures changes the user applied to the generated code after the last agent run.
Use it to understand what the user was dissatisfied with. Do NOT re-apply these changes —
they may already be in place, or may have been reverted before this command runs.

<if userDiffPath provided: @file:<userDiffPath>>
<if no diff: (no diff provided)>

## Inline Comments

<paste inline comments here>
<if none: (no inline comments)>

## Free-form Feedback

<paste free-form feedback text here>
<if none: (no additional feedback)>

## Specification Context

<if spec file reference found: @file:<spec-path>>

## Step to Execute

<paste the step section here>

---

Execute this step now:
1. Read any @file: references above for context
2. Use the diff, inline comments, and feedback to understand what was wrong
3. Perform the actions listed in the step, correcting the issues described
4. Validate ALL success criteria
5. Report your results — include which files were changed

Remember: Execute THIS step ONLY. Do not modify the plan file.
```

---

## Technical Design

### Architecture

```
refine-plan:
  User input: plan-file + step-name + userDiffPath + multi-line body
    ↓
  Read plan file + diff file (if provided)
    ↓
  Task → general-purpose agent
    ├─ Plan content + step name
    ├─ Diff content (if any)
    ├─ Inline comments + free-form feedback
    └─ Agent edits plan file
    ↓
  Report changes to user

refine-generation:
  User input: plan-file + step-name + userDiffPath + multi-line body
    ↓
  Read plan file + diff file (if provided)
  Find and extract step by name (plan unchanged)
    ↓
  Task → step-executor agent
    ├─ Spec file (from References)
    ├─ Step content
    ├─ Diff content (if any)
    └─ Inline comments + free-form feedback
    ↓
  Validate agent work (same as execute command)
    ↓
  Report results + suggest next step

refine-plan-and-generation:
  User input: plan-file + step-name + userDiffPath + multi-line body
    ↓
  Read plan file + diff file (if provided)
    ↓
  Task → general-purpose agent     [Phase 1: refine plan]
    ├─ Plan content + step name
    ├─ Diff content (if any)
    └─ Inline comments + free-form feedback
    ↓
  Re-read updated plan
  Find and extract updated step by name
    ↓
  Task → step-executor agent       [Phase 2: re-execute step]
    ├─ Spec file (from References)
    ├─ Updated step content
    ├─ Diff content (if any)
    └─ Inline comments + free-form feedback
    ↓
  Validate agent work (same as execute command)
    ↓
  Report results + suggest next step
```

### Files to Create

| File | Purpose |
|---|---|
| `commands/refine-plan.md` | `refine-plan` command implementation |
| `commands/refine-generation.md` | `refine-generation` command implementation |
| `commands/refine-plan-and-generation.md` | `refine-plan-and-generation` command implementation |

No new agents are needed — all three commands reuse `general-purpose` and `step-executor`.

---

## Edge Cases

| Case | Handling |
|---|---|
| Plan file not found | Error + stop |
| Missing arguments | Show usage + stop |
| Feedback is ambiguous | Agent applies best interpretation, notes assumption |
| Step not found | Error: "Step not found: <name>. Available steps: ..." |
| Agent fails to edit plan | Show error, plan file unchanged |
| Agent hallucination (claims edits, no changes) | Warn user, suggest retry |

---

## Security Considerations

- Commands only operate on files within the project
- No external calls
- Agent runs with user permissions under Claude Code safety rules

---

## Testing Strategy

### Test 1: refine-plan — add a step (no diff)
```
/spec-buddy:refine-plan .specs/plans/add-auth.md "Step 1: Setup" ""
Add a step for input sanitization before step 2.
```
Expected: Plan gains a new step after Setup, no code files changed.

### Test 2: refine-plan — rewrite a step (with diff file)
```
/spec-buddy:refine-plan .specs/plans/add-auth.md "Step 2: Hash Password" ./my.diff
### Inline comments
- src/auth/hash.ts:12: use rounds=10 not 12
```
Expected: Hash Password step in plan updated, all other steps unchanged.

### Test 3: refine-generation — fix code without plan change
```
/spec-buddy:refine-generation .specs/plans/add-auth.md "Step 2: Hash Password" ./my.diff
### Inline comments
- src/auth/hash.ts:8: must be async

Use await bcrypt.hash() instead of bcrypt.hashSync().
```
Expected: Hash Password step re-executed; code file updated to use async hash; plan file unchanged.

### Test 4: refine-plan-and-generation — fix both
```
/spec-buddy:refine-plan-and-generation .specs/plans/add-auth.md "Step 2: Hash Password" ./my.diff
Use await bcrypt.hash() instead of bcrypt.hashSync().
```
Expected: Hash Password step in plan updated to mention async; step re-executed; code file updated to use async hash.

### Test 5: Missing arguments
```
/spec-buddy:refine-plan
```
Expected: Usage message shown, no changes.

---

## Open Questions

1. **Multi-step regeneration**: Should `refine-plan-and-generation` support re-running multiple steps (e.g., multiple quoted names) when the feedback affects several steps?
2. **Plan diff display**: Should the command show a before/after diff of the plan changes?
3. **Git integration**: Should refinements auto-commit the plan change before re-execution?

---

## Implementation Plan

### Step 1: Create refine-plan command

Create the `commands/refine-plan.md` command file implementing the `refine-plan` command.

**Context:**
- See `commands/execute.md` — reference for command file structure and argument parsing patterns
- See `.specs/refine-actions.md` §Command 1 — full requirements and agent prompt template

**Actions:**
- Create `commands/refine-plan.md` with frontmatter and full instructions
- Instructions must cover: argument parsing, reading the plan file, launching a general-purpose agent with the plan content, step number, and feedback, and reporting changes

**Success Criteria:**
- [ ] `commands/refine-plan.md` exists with correct frontmatter (`description:`)
- [ ] Command parses `<plan-file>`, `<step-name>`, and `<feedback>` from `$ARGUMENTS`
- [ ] Shows usage error when arguments are missing
- [ ] Reads plan file; shows error if not found
- [ ] Launches Task tool with general-purpose agent and correct prompt template
- [ ] Agent prompt instructs: edit plan only, do not touch source code
- [ ] Reports which steps were changed after agent completes

---

### Step 2: Create refine-generation command

Create the `commands/refine-generation.md` command file implementing the `refine-generation` command.

**Context:**
- See `commands/execute.md` — reference for step extraction logic and step-executor agent usage
- See `.specs/refine-actions.md` §Command 3 — full requirements and agent prompt template

**Actions:**
- Create `commands/refine-generation.md` with frontmatter and full instructions
- Instructions must cover: argument parsing, reading the plan file, extracting the specified step, launching the step-executor agent with feedback context, post-execution validation, and reporting results

**Success Criteria:**
- [ ] `commands/refine-generation.md` exists with correct frontmatter
- [ ] Command parses `<plan-file>`, `<step-name>`, and `<feedback>` from `$ARGUMENTS`
- [ ] Shows usage error when arguments are missing
- [ ] Reads plan file; shows error if not found
- [ ] Finds step by matching `<step-name>` against plan headings; lists available steps if not found
- [ ] Launches Task tool with step-executor agent; passes step content and feedback
- [ ] Agent prompt includes explicit instruction: do NOT modify the plan file
- [ ] Applies same post-execution validation as `execute` command (checks agent actually used tools)
- [ ] Confirms to user that plan was not modified
- [ ] Suggests next step after completion

---

### Step 3: Create refine-plan-and-generation command

**Note on `<userDiffPath>`:** The diff passed to this command captures manual edits the user made to the generated code after the previous agent execution. These edits express the user's original intent: they may include corrective code changes (showing the right implementation directly) as well as inline wishes written as code comments. This overlaps intentionally with the `### Inline comments` body section — both signals should be forwarded to the agent so it has the fullest picture of what needs to change.

Create the `commands/refine-plan-and-generation.md` command file implementing the `refine-plan-and-generation` command.

**Context:**
- See `commands/refine-plan.md` (created in Step 1) — Phase 1 plan refinement logic
- See `commands/refine-generation.md` (created in Step 2) — Phase 2 step re-execution logic
- See `.specs/refine-actions.md` §Command 2 — full requirements and agent prompt templates

**Actions:**
- Create `commands/refine-plan-and-generation.md` with frontmatter and full instructions
- Instructions must cover two sequential phases: (1) plan refinement agent, (2) step-executor agent with feedback

**Success Criteria:**
- [ ] `commands/refine-plan-and-generation.md` exists with correct frontmatter
- [ ] Command parses `<plan-file>`, `<step-name>`, and `<feedback>` from `$ARGUMENTS`
- [ ] Shows usage error when arguments are missing
- [ ] Phase 1: launches general-purpose agent to edit plan; waits for completion
- [ ] Phase 2: re-reads the updated plan, extracts the updated step, launches step-executor agent
- [ ] Phase 2 agent prompt includes the feedback so it knows what to correct
- [ ] Applies post-execution validation after Phase 2
- [ ] Reports plan changes (Phase 1) and code changes (Phase 2) separately
- [ ] Suggests next step after completion

---

## References

- `.specs/plan-execution-command.md` — execute command specification
- `.specs/implementation-plan-command.md` — plan creation
- `commands/execute.md` — execute command implementation
- `CLAUDE.md` — plugin architecture
