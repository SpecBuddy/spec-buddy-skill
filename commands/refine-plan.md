---
description: Refine an implementation plan based on feedback and a diff about a specific step
---

# Refine Plan Command

Edit an implementation plan based on user feedback about a step that was just executed. Does **not** touch any source code or implementation files — only the plan file is modified.

## Usage

```
/spec-buddy:refine-plan <plan-file> <step-name> <userDiffPath>
### Inline comments
- <filePath>:<lineNumber>: <comment>

Free form feedback
```

**Arguments (first line):**
- `<plan-file>`: Path to the implementation plan markdown file
- `<step-name>`: Quoted name of the step that was just executed (e.g., `"Step 2: Hash Password"`)
- `<userDiffPath>`: Path to a diff file containing the user's manual edits to the generated code after the previous execution (e.g., saved with `git diff > my.diff`), or an empty string (`""`) if no diff. Read as evidence of what the user was dissatisfied with — not applied mechanically. The changes it records may already be in place, or may have been reverted before this command runs.

**Multi-line body (optional, everything after the first line of `$ARGUMENTS`):**
- `### Inline comments` section — per-line comments as `<filePath>:<lineNumber>: <comment>`
- Free-form feedback text below the inline comments section (or anywhere in the body)

**Examples:**
```
/spec-buddy:refine-plan .specs/plans/add-auth.md "Step 2: Hash Password" ./my.diff
### Inline comments
- src/auth/hash.ts:12: bcrypt rounds should be 6, not 12

Add a step for input validation before hashing.
```

```
/spec-buddy:refine-plan .specs/plans/add-auth.md "Step 1: Setup" ""
Add a step for input sanitization before step 2.
```

## Instructions

When this command is invoked, follow these steps:

### 1. Parse Arguments

`$ARGUMENTS` may span multiple lines. Parse it as follows:

**First line** — contains the three positional arguments:
- Split the first line on whitespace, respecting quoted strings
- Token 1: `<plan-file>` — the plan file path (unquoted)
- Token 2: `<step-name>` — the step name, possibly quoted (strip surrounding quotes)
- Token 3: `<userDiffPath>` — the diff file path, or `""` / empty if no diff

**Remaining lines** — the multi-line body (everything after the first line):
- Extract the `### Inline comments` section if present: all lines matching `- <filePath>:<lineNumber>: <comment>` that appear under `### Inline comments`
- Everything else in the body is free-form feedback text

If the first line is missing or contains fewer than 2 tokens (`<plan-file>` and `<step-name>` are required):
- Show error:
  ```
  Error: Missing arguments

  Usage: /spec-buddy:refine-plan <plan-file> <step-name> <userDiffPath>
  ### Inline comments
  - <filePath>:<lineNumber>: <comment>

  Free form feedback

  Example:
    /spec-buddy:refine-plan .specs/plans/add-auth.md "Step 2: Hash Password" ./my.diff
    ### Inline comments
    - src/auth/hash.ts:12: bcrypt rounds should be 6, not 12

    Add a step for input validation before hashing.
  ```
- Stop execution

### 2. Read Plan File

Use the Read tool to load the plan file:
- If the file is not found, show error:
  ```
  Error: Plan file not found: <path>

  Make sure the path is correct. Plans are typically in .specs/plans/
  ```
- List similar files in `.specs/plans/` if available
- Stop execution

### 3. Read Diff File (if provided)

If `<userDiffPath>` is non-empty and not `""`:
- Use the Read tool to load the diff file
- If the diff file is not found:
  - Show warning: `Warning: Diff file not found: <userDiffPath> — continuing without it`
  - Set diff content to `(diff file not found)`
  - Continue (do not stop)
- If found, store the diff content for use in the agent prompt

If `<userDiffPath>` is empty or `""`, set diff content to `(no diff provided)`.

### 4. Launch Plan Refinement Agent

Use the Task tool to launch a general-purpose agent with the following prompt.

Fill in all placeholders before launching:
- Replace `<plan-file>` with the actual plan file path
- Replace `<step-name>` with the actual step name provided by the user
- Replace the diff section with actual diff content or `(no diff provided)`
- Replace the inline comments section with the extracted inline comments or `(no inline comments)`
- Replace the free-form feedback section with the extracted free-form text or `(no additional feedback)`

```
Task tool parameters:
- description: "Refine plan <plan-file> based on feedback about <step-name>"
- prompt: [see template below]
```

**Agent Prompt Template:**

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

<if userDiffPath provided and file was found: @file:<userDiffPath>>
<if no diff or file not found: (no diff provided)>

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
4. Report a brief summary of the changes you made (which steps were added, modified, or removed)

Rules:
- Do NOT touch any source code files
- Only modify the plan file itself
- If the feedback is ambiguous, apply the most reasonable interpretation and note your assumption
```

### 5. Report Changes

After the agent completes:
1. Show the agent's summary of changes
2. Highlight which steps were added, modified, or removed
3. Remind the user that no source code was changed

If the agent reports no changes were made or appears to have hallucinated:
- Warn the user:
  ```
  Warning: The agent did not report any changes to the plan.

  This may indicate the feedback was unclear or the agent did not perform work.
  Suggestions:
  - Retry with more specific feedback
  - Check the plan file manually to confirm its current state
  ```

## Error Handling

### Missing Arguments
```
Error: Missing arguments

Usage: /spec-buddy:refine-plan <plan-file> <step-name> <userDiffPath>
### Inline comments
- <filePath>:<lineNumber>: <comment>

Free form feedback

Example:
  /spec-buddy:refine-plan .specs/plans/add-auth.md "Step 2: Hash Password" ./my.diff
  ### Inline comments
  - src/auth/hash.ts:12: bcrypt rounds should be 6, not 12

  Add a step for input validation before hashing.
```

### Plan File Not Found
```
Error: Plan file not found: <path>

Make sure the path is correct. Plans are typically in .specs/plans/
```

### Diff File Not Found
```
Warning: Diff file not found: <userDiffPath> — continuing without it
```

## Examples

### Example 1: Rewrite a step with a diff and inline comment
```
User: /spec-buddy:refine-plan .specs/plans/add-auth.md "Step 2: Hash Password" ./my.diff
      ### Inline comments
      - src/auth/hash.ts:12: use rounds=10 not 12

→ Reads .specs/plans/add-auth.md
→ Reads ./my.diff
→ Extracts inline comment: src/auth/hash.ts:12: use rounds=10 not 12
→ Launches general-purpose agent with plan content, diff, and inline comment
→ Agent updates Step 2 to specify rounds=10
→ Reports: "Modified Step 2: Hash Password — updated bcrypt rounds from 12 to 10"
→ Confirms: No source code files were changed
```

### Example 2: Add a new step without a diff
```
User: /spec-buddy:refine-plan .specs/plans/add-auth.md "Step 1: Setup" ""
      Add a step for input sanitization before step 2.

→ Reads .specs/plans/add-auth.md
→ No diff (empty string provided)
→ Free-form feedback: "Add a step for input sanitization before step 2."
→ Agent inserts new step between Step 1 and Step 2
→ Reports: "Added Step 2: Input Sanitization (previous Step 2 renumbered to Step 3)"
→ Confirms: No source code files were changed
```

### Example 3: Diff file not found — continues with warning
```
User: /spec-buddy:refine-plan .specs/plans/add-auth.md "Step 3: Tests" ./missing.diff
      The tests should use jest.mock, not sinon.

→ Reads .specs/plans/add-auth.md
→ Attempts to read ./missing.diff — not found
→ Warning: Diff file not found: ./missing.diff — continuing without it
→ Launches agent with plan + free-form feedback only
→ Agent updates Step 3 accordingly
→ Reports changes
```

### Example 4: Missing arguments
```
User: /spec-buddy:refine-plan

→ Error: Missing arguments (shown with full usage)
→ Stop
```

## Related Commands

- `/spec-buddy:execute` - Execute a step from the plan
- `/spec-buddy:refine-generation` - Re-execute a step to fix code (plan unchanged)
- `/spec-buddy:refine-plan-and-generation` - Refine the plan AND re-execute the step

---

**Philosophy**: Plan refinement is separate from code generation. This command fixes the map, not the territory. Use `/spec-buddy:refine-generation` when the plan is correct but the code output was wrong.
