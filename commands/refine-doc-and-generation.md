---
description: Refine any markdown document based on feedback and re-execute the affected step to fix the code
---

# Refine Document and Generation Command

Update a markdown document based on user feedback, then re-execute the affected step to regenerate the implementation code.

## Usage

```
/spec-buddy:refine-doc-and-generation <doc-file> <step-name> <userDiffPath>
### Inline comments
- <filePath>:<lineNumber>: <comment>

Free form feedback
```

**Arguments (first line):**
- `<doc-file>`: Path to the markdown document file (plan, spec, or any other document)
- `<step-name>`: Quoted name of the step to refine and re-execute (e.g., `"Step 2: Hash Password"`)
- `<userDiffPath>`: Path to a diff file with the user's manual edits after the previous execution, or `""` if none. Read as evidence of what the user was dissatisfied with — not applied mechanically.

**Multi-line body (optional):**
- `### Inline comments` section — per-line comments as `<filePath>:<lineNumber>: <comment>`
- Free-form feedback text (anywhere in the body outside the inline comments section)

## Instructions

### 1. Parse Arguments

`$ARGUMENTS` may span multiple lines.

**First line** — three positional arguments (respect quoted strings):
- Token 1: `<doc-file>`
- Token 2: `<step-name>` (strip surrounding quotes)
- Token 3: `<userDiffPath>` — `""` or empty means no diff

**Remaining lines** — extract the `### Inline comments` section and any free-form feedback text.

If `<doc-file>` or `<step-name>` are missing, show a usage error and stop.

### 2. Read Document File

Read the document file. If not found, show an error and stop.

### 3. Read Diff File

If `<userDiffPath>` is non-empty and not `""`, read the diff file. If not found, continue with `(no diff provided)`. If empty or `""`, set diff content to `(no diff provided)`.

---

## Phase 1: Refine the Document

### 4. Launch Document Refinement Agent

Use the Task tool to launch a general-purpose agent. Fill in all placeholders before launching.

```
Task tool parameters:
- description: "Refine document <doc-file> based on feedback about <step-name>"
- prompt: [see template below]
```

**Phase 1 Agent Prompt Template:**

```markdown
You are refining a document based on user feedback about a specific step.

## Current Document

@file:<doc-file>

## Context

The user just executed step "<step-name>" and has feedback about it.

## Diff (manual edits the user made after the previous execution)

This diff captures changes the user applied to the generated code after the last agent run.
Use it to understand what the user was dissatisfied with. Do NOT re-apply these changes —
they may already be in place, or may have been reverted before this command runs.

<if userDiffPath provided and file was found: @file:<userDiffPath>>
<if no diff or file not found: (no diff provided)>

## Inline Comments

<paste inline comments here, e.g.:
- src/auth/hash.ts:8: function should be async>
<if none: (no inline comments)>

## Free-form Feedback

<paste free-form feedback text here>
<if none: (no additional feedback)>

## Task

Edit the document file to reflect the feedback. Only modify the document — do not touch source code.

1. Read the document carefully
2. Read the diff and comments to understand what went wrong in the implementation
3. Edit the document file (using the Edit or Write tool) to apply the requested changes
4. Report a brief summary of the changes you made

Rules:
- Do NOT touch any source code files
- Only modify the document file itself
- If the feedback is ambiguous, apply the most reasonable interpretation and note your assumption
```

Wait for this agent to complete before proceeding to Phase 2.

---

## Phase 2: Re-execute the Updated Step

### 5. Re-read the Updated Document

Re-read the document file after Phase 1 modifications to get the updated step content.

### 6. Find the Requested Step

Scan the updated document for headings matching `<step-name>` (case-insensitive). Extract the full step section. If not found, list available steps, show an error, and stop.

### 7. Extract Specification Reference

Check the document's `## References` section for a spec file path (`@file:<path>`). Note it for use in Phase 2 if found.

### 8. Launch Step Executor Agent

Use the Task tool to launch the `step-executor` agent. Fill in all placeholders before launching.

```
Task tool parameters:
- subagent_type: "step-executor"
- description: "Re-execute step <step-name> from <doc-file> with corrective feedback (after document update)"
- prompt: [see template below]
```

**Phase 2 Agent Prompt Template:**

```markdown
You are re-executing a plan step after the document was just refined.

🎯 CRITICAL: Execute ONLY the step shown below. Do NOT execute other steps.

## Diff (manual edits the user made after the previous execution)

This diff captures changes the user applied to the generated code after the last agent run.
Use it to understand what the user was dissatisfied with. Do NOT re-apply these changes —
they may already be in place, or may have been reverted before this command runs.

<if userDiffPath provided and file was found: @file:<userDiffPath>>
<if no diff or file not found: (no diff provided)>

## Inline Comments

<paste inline comments here, e.g.:
- src/auth/hash.ts:8: function should be async>
<if none: (no inline comments)>

## Free-form Feedback

<paste free-form feedback text here>
<if none: (no additional feedback)>

## Specification Context

<if spec file reference found: @file:<spec-path>>
<if no spec reference found: (No specification provided - working with step context only)>

## Step to Execute (from updated document)

<paste the complete updated step section here, from its heading to the next heading>

---

Execute this step now:
1. Read any @file: references above for context
2. Use the diff, inline comments, and feedback to understand what was wrong previously
3. Perform the actions listed in the step, correcting the issues described
4. Validate ALL success criteria
5. Report your results — include which files were changed

Remember: Execute THIS step ONLY. Do not proceed to other steps.
```

### 9. Validate and Report

After Phase 2 completes, verify the agent performed actual work (used tools, created/modified reported files). If validation fails, show an error noting that Phase 1 document changes are still in effect and the user can retry with `/spec-buddy:refine-generation`.

Show Phase 1 summary (document changes) and Phase 2 summary (code changes) separately. Identify the next step in the document if one exists.
