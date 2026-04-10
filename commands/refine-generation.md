---
description: Re-execute a plan step with corrective feedback, without modifying the plan
---

# Refine Generation Command

Re-execute a step using user feedback to correct previously generated code. The plan file is **not** modified.

## Usage

```
/spec-buddy:refine-generation <plan-file> <step-name> <userDiffPath>
### Inline comments
- <filePath>:<lineNumber>: <comment>

Free form feedback
```

**Arguments (first line):**
- `<plan-file>`: Path to the implementation plan markdown file
- `<step-name>`: Quoted name of the step to re-execute (e.g., `"Step 2: Hash Password"`)
- `<userDiffPath>`: Path to a diff file with user's manual edits after previous execution, or `""` if none.

**Multi-line body (optional):**
- `### Inline comments` section — per-line comments as `<filePath>:<lineNumber>: <comment>`
- Free-form feedback text (anywhere in the body outside the inline comments section)

## Instructions

### 1. Parse Arguments

`$ARGUMENTS` may span multiple lines.

**First line** — three positional arguments (respect quoted strings):
- Token 1: `<plan-file>`
- Token 2: `<step-name>` (strip surrounding quotes)
- Token 3: `<userDiffPath>` — `""` or empty means no diff

**Remaining lines** — extract the `### Inline comments` section and any free-form feedback text.

If `<plan-file>` or `<step-name>` are missing, show a usage error and stop.

### 2. Read Plan File

Read the plan file. If not found, show an error and stop.

### 3. Read Diff File

If `<userDiffPath>` is non-empty and not `""`, read the diff file. If not found, continue with `(no diff provided)`.

### 4. Find the Requested Step

Scan for headings matching `<step-name>` (case-insensitive). Extract the full step section. If not found, list available steps, show an error, and stop.

### 5. Extract Specification Reference

Check the plan's `## References` section for a spec file path (`@file:<path>`). Note it for use in the agent prompt if found.

### 6. Launch Step Executor Agent

Use the Task tool to launch the `step-executor` agent. Fill in all placeholders before launching.

```
Task tool parameters:
- subagent_type: "step-executor"
- description: "Re-execute step <step-name> from <plan-file> with corrective feedback"
- prompt: [see template below]
```

**Agent Prompt Template:**

```markdown
You are re-executing a plan step to fix an issue in the previously generated code.

🎯 CRITICAL: Execute ONLY the step shown below. Do NOT execute other steps.
   The plan file must NOT be modified — only fix the implementation code.

## Diff (manual edits the user made after the previous execution)

This diff captures changes the user applied to the generated code after the last agent run.
Use it to understand what the user was dissatisfied with. Do NOT re-apply these changes —
they may already be in place, or may have been reverted before this command runs.

<if userDiffPath provided and file was found: @file:<userDiffPath>>
<if no diff or file not found: (no diff provided)>

## Inline Comments

<paste inline comments here, e.g.:
- src/auth/hash.ts:8: must be async>
<if none: (no inline comments)>

## Free-form Feedback

<paste free-form feedback text here>
<if none: (no additional feedback)>

## Specification Context

<if spec file reference found: @file:<spec-path>>
<if no spec reference found: (No specification provided - working with step context only)>

## Step to Execute

<paste the complete step section here, from its heading to the next heading>

---

Execute this step now:
1. Read any @file: references above for context
2. Use the diff, inline comments, and feedback to understand what was wrong
3. Perform the actions listed in the step, correcting the issues described
4. Validate ALL success criteria
5. Report your results — include which files were changed

Remember: Execute THIS step ONLY. Do not modify the plan file.
```

### 7. Validate and Report

After the agent completes, verify it performed actual work (used tools, created/modified reported files). If validation fails, show an error suggesting retry.

Show the agent's results and confirm the plan file was not modified. Identify the next step if one exists.
