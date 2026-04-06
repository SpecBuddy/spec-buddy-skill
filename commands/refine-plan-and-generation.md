---
description: Refine an implementation plan based on feedback and re-execute the affected step to fix the code
---

# Refine Plan and Generation Command

Update an implementation plan based on user feedback, then re-execute the affected step to regenerate the implementation code. This command combines `/spec-buddy:refine-plan` (Phase 1) and `/spec-buddy:refine-generation` (Phase 2) in sequence.

Use this when both the plan reasoning and the code output need to be corrected.

## Usage

```
/spec-buddy:refine-plan-and-generation <plan-file> <step-name> <userDiffPath>
### Inline comments
- <filePath>:<lineNumber>: <comment>

Free form feedback
```

**Arguments (first line):**
- `<plan-file>`: Path to the implementation plan markdown file
- `<step-name>`: Quoted name of the step to refine and re-execute (e.g., `"Step 2: Hash Password"`)
- `<userDiffPath>`: Path to a diff file containing the user's manual edits to the generated code after the previous execution (e.g., saved with `git diff > my.diff`), or an empty string (`""`) if no diff. Read as evidence of what the user was dissatisfied with — not applied mechanically. The changes it records may already be in place, or may have been reverted before this command runs.

**Multi-line body (optional, everything after the first line of `$ARGUMENTS`):**
- `### Inline comments` section — per-line comments as `<filePath>:<lineNumber>: <comment>`
- Free-form feedback text below the inline comments section (or anywhere in the body)

**Examples:**
```
/spec-buddy:refine-plan-and-generation .specs/plans/add-auth.md "Step 2: Hash Password" ./my.diff
### Inline comments
- src/auth/hash.ts:8: function should be async

The password hashing function should use await hash() instead of hashSync().
```

```
/spec-buddy:refine-plan-and-generation .specs/plans/add-auth.md "Step 1: Setup" ""
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

  Usage: /spec-buddy:refine-plan-and-generation <plan-file> <step-name> <userDiffPath>
  ### Inline comments
  - <filePath>:<lineNumber>: <comment>

  Free form feedback

  Example:
    /spec-buddy:refine-plan-and-generation .specs/plans/add-auth.md "Step 2: Hash Password" ./my.diff
    ### Inline comments
    - src/auth/hash.ts:8: function should be async

    The password hashing function should use await hash() instead of hashSync().
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
- If found, store the diff content for use in the agent prompts

If `<userDiffPath>` is empty or `""`, set diff content to `(no diff provided)`.

---

## Phase 1: Refine the Plan

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

**Phase 1 Agent Prompt Template:**

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
- src/auth/hash.ts:8: function should be async>
<if none: (no inline comments)>

## Free-form Feedback

<paste free-form feedback text here>
<if none: (no additional feedback)>

## Task

Edit the plan file to reflect the feedback. Only modify the plan — do not touch source code.

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

**Wait for this agent to complete before proceeding to Phase 2.**

### 5. Report Phase 1 Results

After the Phase 1 agent completes:
1. Show the agent's summary of plan changes
2. Highlight which steps were added, modified, or removed
3. If the agent reports no changes or appears to have hallucinated:
   ```
   Warning: Phase 1 agent did not report any changes to the plan.

   This may indicate the feedback was unclear or the agent did not perform work.
   Suggestions:
   - The plan may already reflect the feedback
   - Check the plan file manually to confirm its current state
   - Consider retrying with more specific feedback
   ```
   Continue to Phase 2 regardless — the user's feedback still needs to be applied to the code.

---

## Phase 2: Re-execute the Updated Step

### 6. Re-read the Updated Plan

Use the Read tool to re-read the plan file after Phase 1 modifications:
- This ensures Phase 2 uses the updated step content, not the original

### 7. Find the Requested Step

Scan the updated plan content for headings that match `<step-name>`:
- Search for headings (lines starting with `#`) that contain the step name (case-insensitive)
- Extract all content from that heading until the next heading of the same or higher level, or end of file

If the step is not found in the updated plan:
- List all step headings found in the plan
- Show error:
  ```
  Error: Step not found after plan update: "<step-name>"

  Available steps in <plan-file>:
    - Step 1: <title>
    - Step 2: <title>
    - ...

  The plan was updated in Phase 1 but the step heading may have changed.
  Use /spec-buddy:execute <plan-file> <step-name> with the correct step name.
  ```
- Stop execution

### 8. Extract Specification Reference

Check the updated plan for a References section that includes a spec file path:
- Look for a line like `- @file:<path>` or `- path/to/spec.md` in a `## References` section
- If found, note the spec file path for use in the agent prompt
- If not found, the agent will work with step context only

### 9. Launch Step Executor Agent

Use the Task tool to launch the `step-executor` agent with the updated step content, feedback context, and spec reference.

Fill in all placeholders before launching:
- Replace `<step-name>` with the actual step name
- Replace `<plan-file>` with the actual plan file path
- Replace the diff section with actual diff content or `(no diff provided)`
- Replace the inline comments section with the extracted inline comments or `(no inline comments)`
- Replace the free-form feedback section with the extracted free-form text or `(no additional feedback)`

```
Task tool parameters:
- subagent_type: "step-executor"
- description: "Re-execute step <step-name> from <plan-file> with corrective feedback (after plan update)"
- prompt: [see template below]
```

**Phase 2 Agent Prompt Template:**

```markdown
You are re-executing a plan step after the plan was just refined.

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

## Step to Execute (from updated plan)

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

### 10. Validate Agent Work

After the Phase 2 agent completes, verify it actually performed work:

1. **Check Tool Usage**: Review the agent's response
   - If no tools were called, this is a red flag — the agent may have hallucinated completion without doing actual work

2. **Verify File Changes**: If the agent reports creating or modifying files:
   - Use Bash `ls -l` to verify the reported files exist
   - Check that modification timestamps are recent
   - If reported files don't exist, report a validation error

3. **Validation outcome**:
   - If validation passes: Continue to step 11
   - If validation fails: Show error message:
     ```
     Validation Failed: Phase 2 agent reported completion but did not perform actual work

     The agent claimed to create/modify files but they don't exist, or the agent
     didn't use any tools. This is a hallucination.

     Note: Phase 1 plan changes were already applied and are still in effect.

     Suggestions:
     - Retry code regeneration: /spec-buddy:refine-generation <plan-file> "<step-name>" <userDiffPath>
     - Check the agent transcript for details
     - Report this issue if it persists
     ```

### 11. Display Results

After validation passes:

1. **Show Phase 1 Summary** (plan changes):
   ```
   ## Phase 1: Plan Updated

   <agent's summary of plan changes — which steps were added, modified, or removed>
   ```

2. **Show Phase 2 Summary** (code changes):
   ```
   ## Phase 2: Step Re-executed

   <agent's structured results report>
   ```

3. **Identify Next Step** (if available):
   - Parse the updated plan to find all step headings
   - Find the step that comes after the current one
   - If found: "Next: `/spec-buddy:execute <plan-file> <next-step-name>`"
   - If the current step was the last: "All steps in plan completed!"

## Error Handling

### Missing Arguments
```
Error: Missing arguments

Usage: /spec-buddy:refine-plan-and-generation <plan-file> <step-name> <userDiffPath>
### Inline comments
- <filePath>:<lineNumber>: <comment>

Free form feedback

Example:
  /spec-buddy:refine-plan-and-generation .specs/plans/add-auth.md "Step 2: Hash Password" ./my.diff
  ### Inline comments
  - src/auth/hash.ts:8: function should be async

  The password hashing function should use await hash() instead of hashSync().
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

### Step Not Found After Plan Update
```
Error: Step not found after plan update: "<step-name>"

Available steps in <plan-file>:
  - Step 1: <title>
  - Step 2: <title>
  - Step 3: <title>

The plan was updated in Phase 1 but the step heading may have changed.
Use /spec-buddy:execute <plan-file> <step-name> with the correct step name.
```

### Phase 2 Agent Hallucination Detected
```
Validation Failed: Phase 2 agent reported completion but did not perform actual work

The agent claimed to modify <file> but the file was not changed.
This may be a hallucination — the agent reported work without actually using tools.

Note: Phase 1 plan changes were already applied and are still in effect.

Suggestions:
- Retry code regeneration: /spec-buddy:refine-generation <plan-file> "<step-name>" <userDiffPath>
- The retry will include explicit reminders to use Write/Edit tools
```

## Examples

### Example 1: Fix Both Plan and Code
```
User: /spec-buddy:refine-plan-and-generation .specs/plans/add-auth.md "Step 2: Hash Password" ./my.diff
      ### Inline comments
      - src/auth/hash.ts:8: function should be async

      The password hashing function should use await hash() instead of hashSync().

Phase 1:
→ Reads .specs/plans/add-auth.md
→ Reads ./my.diff
→ Extracts inline comment: src/auth/hash.ts:8: function should be async
→ Extracts free-form feedback: "The password hashing function should use await hash() instead of hashSync()."
→ Launches general-purpose agent with plan content, diff, inline comments, and free-form feedback
→ Agent updates Step 2 to specify async bcrypt.hash()
→ Reports: "Modified Step 2: Hash Password — updated to use async bcrypt.hash()"

Phase 2:
→ Re-reads updated .specs/plans/add-auth.md
→ Finds "Step 2: Hash Password" in updated plan
→ Launches step-executor agent with diff, inline comments, free-form feedback, and updated step content
→ Agent updates auth.js to use async bcrypt.hash()
→ Validation: verifies auth.js was modified
→ Reports: "Updated auth.js to use async bcrypt.hash()"
→ Shows: Next: /spec-buddy:execute .specs/plans/add-auth.md "Step 3: ..."
```

### Example 2: Add New Step and Execute It (no diff)
```
User: /spec-buddy:refine-plan-and-generation .specs/plans/add-auth.md "Step 1: Setup" ""
      Add a step for input sanitization before step 2.

Phase 1:
→ Reads .specs/plans/add-auth.md
→ No diff (empty string provided)
→ Free-form feedback: "Add a step for input sanitization before step 2."
→ Agent inserts Step 2: Input Sanitization (previous steps renumbered)
→ Reports: "Added Step 2: Input Sanitization (previous Step 2 renumbered to Step 3)"

Phase 2:
→ Re-reads updated plan
→ Finds "Step 1: Setup" (unchanged)
→ Launches step-executor agent with free-form feedback and updated step content
→ Agent executes Step 1 with correction
```

### Example 3: Missing Arguments
```
User: /spec-buddy:refine-plan-and-generation

Error: Missing arguments

Usage: /spec-buddy:refine-plan-and-generation <plan-file> <step-name> <userDiffPath>
...
```

### Example 4: Diff File Not Found — Continues with Warning
```
User: /spec-buddy:refine-plan-and-generation .specs/plans/add-auth.md "Step 2: Hash Password" ./missing.diff
      Use await hash() instead of hashSync().

→ Reads .specs/plans/add-auth.md
→ Attempts to read ./missing.diff — not found
→ Warning: Diff file not found: ./missing.diff — continuing without it
→ Phase 1: Launches agent with plan + free-form feedback only
→ Phase 2: Launches step-executor agent with free-form feedback only
→ Reports changes for both phases separately
```

## Implementation Notes

- **Sequential phases**: Phase 1 must complete before Phase 2 begins. Phase 2 uses the updated plan, not the original.
- **Re-read after Phase 1**: Always re-read the plan file before Phase 2 — the agent may have changed step names, numbering, or content.
- **Feedback passed to both phases**: The same diff, inline comments, and free-form feedback are given to both the plan-refinement agent (Phase 1) and the step-executor agent (Phase 2) so each can apply the relevant parts.
- **Separate reporting**: Phase 1 changes (plan edits) and Phase 2 changes (code files) are reported distinctly so the user can see what each phase did.
- **Plan changes survive Phase 2 failure**: If Phase 2 validation fails, Phase 1 plan changes remain. The user can retry code generation separately with `/spec-buddy:refine-generation`.
- **Diff as context**: The diff captures the user's manual edits to the generated code after the previous execution. Both agents receive it as evidence of what the user was dissatisfied with — not as changes to apply mechanically. The edits may already be in place or may have been reverted before re-execution.
- **Feedback structure**: The multi-line body separates inline per-line comments from free-form narrative feedback, giving both agents precise context for what was wrong.
- **Spec reference**: If the plan's References section points to a spec file, the Phase 2 agent receives it as `@file:` context, consistent with how `/spec-buddy:execute` works.
- **Validation**: Same hallucination-detection logic as in `execute` — check tool usage and verify reported files exist.
- **User control**: No automatic progression — user decides when to move to the next step.

## Related Commands

- `/spec-buddy:execute` - Execute a step for the first time
- `/spec-buddy:refine-plan` - Update the plan only (does not regenerate code)
- `/spec-buddy:refine-generation` - Regenerate code only (does not modify the plan)

---

**Philosophy**: When both the map and the territory need correction, fix the map first, then re-navigate. This command updates the plan to reflect improved understanding, then regenerates the implementation from that improved plan. The diff, inline comments, and free-form feedback inform both phases so nothing is lost in translation.
