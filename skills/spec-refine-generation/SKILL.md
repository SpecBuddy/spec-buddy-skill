---
name: refine-generation
description: Re-execute a single named step from an implementation plan using user feedback to fix the previously generated code. The plan file itself is NOT modified — only the implementation code is corrected.
triggers:
  - "re-run step `Hash Password` with this feedback"
  - "fix the code from the last step without changing the plan"
  - "re-execute the step to address my comments"
  - "regenerate code for step 2 with these corrections"
  - "the plan is fine but the implementation is wrong, redo it"
  - "apply this feedback to the generated code only"
---

# Refine Generation

Re-execute a single named step from an implementation plan using corrective feedback from the user. The goal is to fix the implementation code that was produced by a previous run. The plan file itself is **not** modified.

## Input Elicitation

Gather these inputs:
- **Plan file path** *(required)* — the markdown plan file that contains the step.
- **Step name** *(required)* — the exact name of the step to re-execute, e.g. `Step 2: Hash Password`.
- **User diff path** *(optional)* — a path to a diff file capturing the manual edits the user applied to the generated code after the last run. Treat this as evidence of what the user was dissatisfied with — do not re-apply it mechanically.
- **Inline comments** *(optional)* — lines of the form `<filePath>:<lineNumber>: <comment>`.
- **Free-form feedback** *(optional)* — additional prose feedback.

If the plan file path or step name is missing, ask the user for them. If the plan file does not exist, report the error and stop.

## Procedure

### 1. Read the Plan File

Read the plan file. If not found, report the error and stop.

### 2. Read the Diff (if provided)

If a diff path was provided and is non-empty, read it. If the file cannot be read, continue with `(no diff provided)`.

### 3. Find the Requested Step

Scan the plan for headings matching the step name (case-insensitive). Extract the full step section — from its heading to the next heading. If not found, list available steps, report the error, and stop.

### 4. Extract Specification Context

Check the plan's `## References` section for a specification file path. If found, read that spec for context. Otherwise work from the step content alone.

### 5. Re-execute the Step

You are now re-executing the step with corrective feedback. Apply the following directly — there is no separate sub-agent to dispatch to.

🎯 CRITICAL: execute ONLY the one step you extracted. Do NOT execute other steps. The plan file MUST NOT be modified — only fix the implementation code.

**You have:**
- (If provided) the user's diff — evidence of changes the user made to the generated code after the last run. Use it to understand what was wrong; do NOT re-apply these changes (they may already be in place, or may have been reverted).
- The user's inline comments (e.g. `src/auth/hash.ts:8: must be async`).
- The user's free-form feedback.
- The specification file (if any) for overall context.
- The full step section for the action plan.

**Workflow:**

1. Read any specification file referenced for overall context.
2. Use the diff, inline comments, and free-form feedback to understand specifically what was wrong with the previous output.
3. Read any files referenced in the step's "Context" section, plus the files implicated by the feedback.
4. Perform the actions listed in the step, correcting the issues described by the feedback.
5. Validate ALL success criteria for the step.
6. Report your results — include exactly which files were created or modified.

**Hard rules:**
- Execute THIS step ONLY. Do not run other steps.
- Do NOT modify the plan file. If the feedback implies the plan itself is wrong, stop and tell the user that they should refine the document first.
- Do NOT touch unrelated code — stay within what the step's actions and the user's feedback call for.

### 6. Validate and Report

After execution, verify that you actually performed work (used tools, created or modified the files you reported). Show:
- What you understood from the feedback.
- The list of files changed.
- The status of each success criterion.
- Confirmation that the plan file was not touched.
- The next step in the plan (for the user's reference, not for you to execute).
