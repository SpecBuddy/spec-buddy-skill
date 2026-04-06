---
description: Re-execute a plan step with corrective feedback, without modifying the plan
---

# Refine Generation Command

Re-execute a specific step from an implementation plan, using user feedback to correct previously generated code. The plan file is **not** modified — only the code produced by the step is regenerated.

Use this when the plan itself is correct but the code output was wrong (a bug, wrong approach in implementation, missed requirement in the generated code).

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
- `<userDiffPath>`: Path to a diff file containing the user's manual edits to the generated code after the previous execution (e.g., saved with `git diff > my.diff`), or an empty string (`""`) if no diff. Read as evidence of what the user was dissatisfied with — not applied mechanically. The changes it records may already be in place, or may have been reverted before this command runs.

**Multi-line body (optional, everything after the first line of `$ARGUMENTS`):**
- `### Inline comments` section — per-line comments as `<filePath>:<lineNumber>: <comment>`
- Free-form feedback text below the inline comments section (or anywhere in the body)

**Example:**
```
/spec-buddy:refine-generation .specs/plans/add-auth.md "Step 2: Hash Password" ./my.diff
### Inline comments
- src/auth/hash.ts:8: must be async

The hash function must use await hash() instead of hashSync().
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

  Usage: /spec-buddy:refine-generation <plan-file> <step-name> <userDiffPath>
  ### Inline comments
  - <filePath>:<lineNumber>: <comment>

  Free form feedback

  Example:
    /spec-buddy:refine-generation .specs/plans/add-auth.md "Step 2: Hash Password" ./my.diff
    ### Inline comments
    - src/auth/hash.ts:8: must be async

    The hash function must use await hash() instead of hashSync().
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

### 4. Find the Requested Step

Scan the plan content for headings that match `<step-name>`:
- Search for headings (lines starting with `#`) that contain the step name (case-insensitive)
- Extract all content from that heading until the next heading of the same or higher level, or end of file

If the step is not found:
- List all step headings found in the plan
- Show error:
  ```
  Error: Step not found: "<step-name>"

  Available steps in <plan-file>:
    - Step 1: <title>
    - Step 2: <title>
    - ...

  Usage: /spec-buddy:refine-generation <plan-file> "<step-name>" <userDiffPath>
  ```
- Stop execution

### 5. Extract Specification Reference

Check the plan for a References section that includes a spec file path:
- Look for a line like `- @file:<path>` or `- path/to/spec.md` in a `## References` section
- If found, note the spec file path for use in the agent prompt
- If not found, the agent will work with step context only

### 6. Launch Step Executor Agent

Use the Task tool to launch the `step-executor` agent. Fill in all placeholders before launching:
- Replace `<step-name>` with the actual step name
- Replace `<plan-file>` with the actual plan file path
- Replace the diff section with actual diff content or `(no diff provided)`
- Replace the inline comments section with the extracted inline comments or `(no inline comments)`
- Replace the free-form feedback section with the extracted free-form text or `(no additional feedback)`

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

### 7. Validate Agent Work

After the agent completes, verify it actually performed work:

1. **Check Tool Usage**: Review the agent's response
   - If no tools were called, this is a red flag — the agent may have hallucinated completion without doing actual work

2. **Verify File Changes**: If the agent reports creating or modifying files:
   - Use Bash `ls -l` to verify the reported files exist
   - Check that modification timestamps are recent
   - If reported files don't exist, report a validation error

3. **Validation outcome**:
   - If validation passes: Continue to step 8
   - If validation fails: Show error message:
     ```
     ⚠️ Validation Failed: Agent reported completion but did not perform actual work

     The agent claimed to create/modify files but they don't exist, or the agent
     didn't use any tools. This is a hallucination.

     Suggestions:
     - Retry: /spec-buddy:refine-generation <plan-file> "<step-name>" <userDiffPath>
     - Check the agent transcript for details
     - Report this issue if it persists
     ```

### 8. Display Results

After validation passes:

1. **Show Agent Output**: Display the agent's structured results report

2. **Confirm Plan Was Not Modified**: Explicitly tell the user:
   ```
   ✓ Plan file unchanged: <plan-file> was not modified.
   ```

3. **Identify Next Step** (if available):
   - Parse the plan to find all step headings
   - Find the step that comes after the current one
   - If found: "Next: `/spec-buddy:execute <plan-file> <next-step-name>`"
   - If the current step was the last: "✓ All steps in plan completed!"

## Error Handling

### Missing Arguments
```
Error: Missing arguments

Usage: /spec-buddy:refine-generation <plan-file> <step-name> <userDiffPath>
### Inline comments
- <filePath>:<lineNumber>: <comment>

Free form feedback

Example:
  /spec-buddy:refine-generation .specs/plans/add-auth.md "Step 2: Hash Password" ./my.diff
  ### Inline comments
  - src/auth/hash.ts:8: must be async

  The hash function must use await hash() instead of hashSync().
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

### Step Not Found
```
Error: Step not found: "<step-name>"

Available steps in <plan-file>:
  - Step 1: <title>
  - Step 2: <title>
  - Step 3: <title>

Usage: /spec-buddy:refine-generation <plan-file> "<step-name>" <userDiffPath>
```

### Agent Hallucination Detected
```
⚠️ Validation Failed: Agent reported completion but did not perform actual work

The agent claimed to modify <file> but the file was not changed.
This may be a hallucination — the agent reported work without actually using tools.

Suggestions:
- Retry: /spec-buddy:refine-generation <plan-file> "<step-name>" <userDiffPath>
- The retry will include explicit reminders to use Write/Edit tools
```

## Examples

### Example 1: Fix Async Bug
```
User: /spec-buddy:refine-generation .specs/plans/add-auth.md "Step 2: Hash Password" ./my.diff
      ### Inline comments
      - src/auth/hash.ts:8: must be async

      Use await bcrypt.hash() instead of bcrypt.hashSync().

→ Reads .specs/plans/add-auth.md
→ Reads ./my.diff
→ Extracts inline comment: src/auth/hash.ts:8: must be async
→ Extracts free-form feedback: "Use await bcrypt.hash() instead of bcrypt.hashSync()."
→ Finds "Step 2: Hash Password" heading (plan unchanged)
→ Launches step-executor agent with diff content, inline comments, feedback, and step content
→ Agent updates auth.js to use async bcrypt.hash()
→ Agent validates success criteria
→ Validation: verifies auth.js was modified
→ Reports: "Updated auth.js to use async bcrypt.hash()"
→ Confirms: "✓ Plan file unchanged: .specs/plans/add-auth.md was not modified."
→ Shows: Next: /spec-buddy:execute .specs/plans/add-auth.md "Step 3: ..."
```

### Example 2: Step Not Found
```
User: /spec-buddy:refine-generation .specs/plans/add-auth.md "Step 9: Nonexistent" ""

Error: Step not found: "Step 9: Nonexistent"

Available steps in .specs/plans/add-auth.md:
  - Step 1: Setup
  - Step 2: Hash Password
  - Step 3: Write Tests
```

### Example 3: Missing Arguments
```
User: /spec-buddy:refine-generation

Error: Missing arguments

Usage: /spec-buddy:refine-generation <plan-file> <step-name> <userDiffPath>
...
```

### Example 4: Diff file not found — continues with warning
```
User: /spec-buddy:refine-generation .specs/plans/add-auth.md "Step 2: Hash Password" ./missing.diff
      Use await hash() instead of hashSync().

→ Reads .specs/plans/add-auth.md
→ Attempts to read ./missing.diff — not found
→ Warning: Diff file not found: ./missing.diff — continuing without it
→ Launches agent with step content + free-form feedback only
→ Agent updates the code accordingly
→ Reports changes
→ Confirms plan was not modified
```

## Implementation Notes

- **Plan is read-only**: The plan file must never be modified by this command or its agent. The `step-executor` agent prompt explicitly forbids plan modification.
- **Diff as context**: The diff captures the user's manual edits to the generated code after the previous execution. It is read as evidence of what the user was dissatisfied with — not applied mechanically. The changes may already be in place or may have been reverted before re-execution.
- **Feedback structure**: The multi-line body separates inline per-line comments from free-form narrative feedback, giving the agent precise context for what was wrong.
- **Step extraction**: Step boundaries are determined by heading levels — extract from the matched heading to the next heading at the same or higher level.
- **Spec reference**: If the plan's References section points to a spec file, the agent receives it as `@file:` context, consistent with how `/spec-buddy:execute` works.
- **Validation**: Same hallucination-detection logic as in `execute` — check tool usage and verify reported files exist.
- **User control**: No automatic progression — user decides when to move to the next step.

## Related Commands

- `/spec-buddy:execute` - Execute a step for the first time
- `/spec-buddy:refine-plan` - Update the plan based on feedback (does not regenerate code)
- `/spec-buddy:refine-plan-and-generation` - Update the plan AND regenerate the step

---

**Philosophy**: The plan is the source of truth. `refine-generation` keeps the plan stable while allowing the code output to be corrected. Use it when the plan's reasoning is sound but the generated implementation needs fixing.
