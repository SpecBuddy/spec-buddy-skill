---
description: Refine any markdown document based on feedback — for a specific step or the whole document
---

# Refine Document Command

Edit a markdown document based on user feedback. Can target a specific step or the entire document. Does **not** touch source code.

## Usage

### Refine a specific step
```
/spec-buddy:refine-doc <doc-file> <step-name> <userDiffPath>
### Inline comments
- <filePath>:<lineNumber>: <comment>

Free form feedback
```

### Refine the whole document
```
/spec-buddy:refine-doc <doc-file>

Free form feedback
```

**Arguments (first line):**
- `<doc-file>` *(required)*: Path to the markdown document file
- `<step-name>` *(optional)*: Quoted step name (e.g., `"Step 2: Hash Password"`). When omitted, feedback applies to the whole document.
- `<userDiffPath>` *(optional, only with step-name)*: Path to a diff file with user's manual edits after previous execution, or `""` if none.

**Multi-line body (optional):**
- `### Inline comments` section — per-line comments as `<filePath>:<lineNumber>: <comment>`
- Free-form feedback text (anywhere in the body outside the inline comments section)

## Instructions

### 1. Parse Arguments

`$ARGUMENTS` may span multiple lines.

**First line** — positional arguments (respect quoted strings):
- Token 1: `<doc-file>` *(required)*
- Token 2: `<step-name>` *(optional)* — if not quoted, treat as free-form feedback
- Token 3: `<userDiffPath>` — `""` or empty means no diff

**Mode:** step-name present → **step mode**; absent → **document mode**.

**Remaining lines** — extract the `### Inline comments` section and any free-form feedback text.

If `<doc-file>` is missing, show a usage error and stop.

### 2. Read Document File

Read the document file. If not found, show an error and stop.

### 3. Read Diff File (step mode only)

Skip in document mode. In step mode, if `<userDiffPath>` is non-empty and not `""`, read the diff file. If not found, continue with `(no diff provided)`.

### 4. Launch Document Refinement Agent

Use the Task tool to launch a general-purpose agent. Fill in all placeholders before launching.

```
Task tool parameters:
- description: "Refine document <doc-file> based on feedback [about <step-name> | on the whole document]"
- prompt: [see template below]
```

**Agent Prompt Template:**

```markdown
You are refining a document based on user feedback.

## Current Document

@file:<doc-file>

## Context

<if step mode:>
The user just executed step "<step-name>" and has feedback about it.
<end if>

<if document mode:>
The user is reviewing the document as a whole and has feedback about its structure, steps, or completeness. No specific step was executed.
<end if>

## Diff (manual edits the user made after the previous execution)

<if step mode:>
This diff captures changes the user applied to the generated code after the last agent run.
Use it to understand what the user was dissatisfied with. Do NOT re-apply these changes —
they may already be in place, or may have been reverted before this command runs.

<if userDiffPath provided and file was found: @file:<userDiffPath>>
<if no diff or file not found: (no diff provided)>
<end if>

<if document mode:>
(not applicable — no step was executed)
<end if>

## Inline Comments

<paste inline comments here, e.g.:
- src/auth/hash.ts:12: bcrypt rounds should be 6, not 12>
<if none: (no inline comments)>

## Free-form Feedback

<paste free-form feedback text here>
<if none: (no additional feedback)>

## Task

1. Read the document carefully
2. <if step mode:> Read the diff and comments to understand what went wrong in the implementation
   <if document mode:> Read the feedback to understand what the user wants changed about the document structure
3. Edit the plan file (using the Edit or Write tool) to apply the requested changes:
   - Rewrite steps that need changing
   - Add new steps if requested
   - Remove steps if requested
   - Reorder or split steps if requested
   - Preserve overall structure and markdown formatting
4. Report a brief summary of the changes you made (which steps were added, modified, or removed)

Rules:
- Do NOT touch any source code files
- Only modify the document file itself
- If the feedback is ambiguous, apply the most reasonable interpretation and note your assumption
```

### 5. Report Changes

After the agent completes, show its summary of changes. If no changes were reported, warn the user that the feedback may have been unclear.
