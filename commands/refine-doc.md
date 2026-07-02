---
description: Refine any markdown document based on feedback — for a specific step or the whole document
---

# Refine Document Command

Edit a markdown document based on user feedback. Can target a specific step or the entire document. Does **not** touch source code. You perform the refinement **directly** — there is no sub-agent to dispatch to.

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

### 4. Refine the Document

Refine the document yourself, applying the feedback in the context of the chosen mode. Gather everything first: the document content (from step 2), the diff (from step 3), the inline comments, and the free-form feedback.

**Context by mode:**
- **Step mode** — the user just executed step `<step-name>` and has feedback about it. The diff captures changes the user applied to the generated code after the last run; use it to understand what the user was dissatisfied with. **Do NOT re-apply the diff** — those changes may already be in place, or may have been reverted before this command runs. Treat the diff as evidence of dissatisfaction, not a patch.
- **Document mode** — the user is reviewing the document as a whole and has feedback about its structure, steps, or completeness. No specific step was executed; there is no diff.

**Apply the changes:**
1. Read the document carefully.
2. In step mode, read the diff and comments to understand what went wrong in the implementation. In document mode, read the feedback to understand what the user wants changed about the document structure.
3. Edit the document file (Edit or Write tool) to apply the requested changes: rewrite steps that need changing, add new steps if requested, remove steps if requested, reorder or split steps if requested. Preserve overall structure and markdown formatting.
4. Report a brief summary of the changes you made (which steps were added, modified, or removed; or section-level changes in document mode).

**Rules:**
- Do **NOT** touch any source code files — only modify the document file itself.
- Preserve the document's overall structure and markdown formatting; leave any HTML-comment annotations exactly as they are.
- If the feedback is ambiguous, apply the most reasonable interpretation and note your assumption.

### 5. Report Changes

Show your summary of changes. If you made no changes, warn the user that the feedback may have been unclear.
