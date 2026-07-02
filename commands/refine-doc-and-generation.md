---
description: Refine any markdown document based on feedback and re-execute the affected step to fix the code
---

# Refine Document and Generation Command

Update a markdown document based on user feedback, then re-execute the affected step to regenerate the implementation code. You perform both phases **directly** — there is no sub-agent to dispatch to.

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

If `<userDiffPath>` is non-empty and not `""`, read the diff file. If not found or empty, use `(no diff provided)`.

---

## Phase 1: Refine the Document

### 4. Apply the Feedback to the Document

Refine the document yourself, based on the user's feedback about step `<step-name>`. Only modify the document — do not touch source code.

The diff captures changes the user applied to the generated code after the last run. Use it to understand what the user was dissatisfied with. **Do NOT re-apply the diff** — those changes may already be in place, or may have been reverted before this command runs.

1. Read the document carefully.
2. Read the diff and comments to understand what went wrong in the implementation.
3. Edit the document file (Edit or Write tool) to apply the requested changes to step `<step-name>`.
4. Note a brief summary of the document changes you made (for the final report).

Rules:
- Do **NOT** touch any source code files — only modify the document file itself.
- Preserve overall structure and markdown formatting; leave any HTML-comment annotations exactly as they are.
- If the feedback is ambiguous, apply the most reasonable interpretation and note your assumption.

Complete Phase 1 fully before starting Phase 2.

---

## Phase 2: Re-execute the Updated Step

### 5. Re-read the Updated Document

Re-read the document file after the Phase 1 edits so you work from the updated step content.

### 6. Find the Requested Step

Scan the updated document for headings matching `<step-name>` (case-insensitive). Extract the full step section (from its heading to the next heading). If not found, list available steps, show an error, and stop.

### 7. Extract Specification Reference

Check the document's `## References` section for a specification file path. If one is found, read that spec for overall context.

### 8. Re-execute the Updated Step

Re-execute the step yourself, now that the document has been refined.

🎯 **CRITICAL: Execute ONLY this step. Do NOT execute other steps.**

Use all available evidence of what was wrong previously — the diff (as evidence, not a patch), the inline comments, the free-form feedback, and the specification context (if any). Then:
1. Read any referenced context (spec, files under the step's "Context" section, line ranges).
2. Use the diff, inline comments, and feedback to understand what was wrong previously.
3. Perform the step's actions, correcting the issues described.
4. Validate ALL of the step's success criteria.

### 9. Verify and Report

1. **Verify your own work** — confirm you actually used tools and that every file you report as changed exists on disk. If verification fails, do not report success: note that the Phase 1 document changes are still in effect, redo the work for real and verify again (the user can also retry with `/spec-buddy:refine-generation`).
2. **Report both phases separately** — Phase 1 summary (document changes) and Phase 2 summary (code changes, files changed, success criteria met).
3. **Propagate discovered context** — if you learned anything relevant for *subsequent* steps, list those items and ask whether to update the next steps in the document. If nothing useful surfaced, skip this silently.
4. **Identify the next step** (do not execute it) in the document if one exists.
