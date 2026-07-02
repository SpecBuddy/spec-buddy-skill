---
description: Re-execute a plan step with corrective feedback, without modifying the plan
---

# Refine Generation Command

Re-execute a step using user feedback to correct previously generated code. The plan file is **not** modified. You perform the re-execution **directly** — there is no sub-agent to dispatch to.

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

Scan for headings matching `<step-name>` (case-insensitive). Extract the full step section (from its heading to the next heading). If not found, list available steps, show an error, and stop.

### 5. Extract Specification Reference

Check the plan's `## References` section for a specification file path. If one is found, read that spec for overall context.

### 6. Re-execute the Step with Corrective Feedback

Re-execute the step yourself to fix the issue in the previously generated code.

🎯 **CRITICAL: Execute ONLY this step. Do NOT execute other steps. Do NOT modify the plan file — only fix the implementation code.**

Use all available evidence of what was wrong:
- **Diff** — the manual edits the user applied to the generated code after the last run. Use it to understand what the user was dissatisfied with. **Do NOT re-apply the diff** — those changes may already be in place, or may have been reverted before this command runs. Treat it as evidence, not a patch.
- **Inline comments** — per-line comments pointing at specific problems.
- **Free-form feedback** — the user's description of what to change.
- **Specification context** — the spec found in step 5 (if any), for overall intent.

Then:
1. Read any referenced context (spec, files under the step's "Context" section, line ranges).
2. Use the diff, inline comments, and feedback to understand what was wrong.
3. Perform the step's actions, correcting the issues described.
4. Validate ALL of the step's success criteria.

### 7. Verify, Report, and Identify Next Step

1. **Verify your own work** — confirm you actually used tools and that every file you report as changed exists on disk (e.g. `ls -l <path>`). If verification fails, do not report success: redo the work for real and verify again.
2. **Report results** — summarize what you changed, list the files changed, and confirm which success criteria were met. Confirm the plan file was **not** modified.
3. **Propagate discovered context** — if you learned anything while re-executing that is relevant for *subsequent* steps (file structures, API shapes, naming conventions, existing patterns, dependency versions, unexpected findings), list those items and ask the user whether to update the next steps in the plan to reference them. If nothing useful surfaced, skip this silently.
4. **Identify the next step** (do not execute it) if one exists in the plan, so the user can decide whether to proceed.
