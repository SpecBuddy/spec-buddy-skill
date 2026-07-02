---
description: Execute one step from an implementation plan
---

# Execute Plan Step Command

Execute a single step from an implementation plan with full specification context. You perform the work **directly** — there is no sub-agent to dispatch to.

## Usage

```
/spec-buddy:execute <plan-file> <step-number>
```

**Arguments:**
- `<plan-file>`: Path to the implementation plan markdown file
- `<step-number>`: Number of the step to execute (e.g., `1`, `2`, `3`)

**Example:**
```
/spec-buddy:execute specs/plans/add-auth.md 1
```

## Instructions

When this command is invoked, follow these steps.

### 1. Parse Arguments

Extract the plan file path and step number from `$ARGUMENTS` (expected format: `<plan-file> <step-number>`). If arguments are missing or malformed, show `Usage: /spec-buddy:execute <plan-file> <step-id>` with an example and stop.

### 2. Read Plan File

Use the Read tool to load the plan file. If not found, show `Plan file not found: <path>`, list similar files in `specs/plans/` if available, and stop.

### 3. Extract Step Content

Find the requested step by its number: scan for headings matching `### Step <N>:` (e.g. `### Step 1: Setup`) and extract all content from that heading until the next `###`-level heading or end of file.

If the step is not found, show `Step <N> not found in plan`, list all available steps (e.g. `Available steps: 1 (Setup), 2 (Implementation), 3 (Tests)`), and stop.

### 4. Extract Specification Context

Check the plan's `## References` section for a specification file path. If one is found, read that spec for overall context. If none is found, work from the step content alone — no warning needed (the step's own `@file:` / backtick references supply what you need).

### 5. Execute the Step

Now switch into focused step-execution mode. The rules below are the executor's instructions — apply them to the single step you extracted in step 3.

🎯 **CRITICAL: Execute ONLY this step. Do NOT execute other steps or proceed beyond it.**

**Workflow:**

1. **Understand overall context** — read the specification (the path from the References section, if any) to understand what is being built: the goals, requirements, and constraints.
2. **Focus on your step** — you are executing ONLY the extracted step. It is a markdown section from its `### Step N:` heading to the next heading; everything you need is in that section.
3. **Review context** — read any files referenced under the step's "Context" section. Use `path#L10-L20` line-range references to examine specific sections. Understand what you are changing before changing it.
4. **Execute actions** — follow the step's "Actions" section. Run listed commands with Bash, read context files with Read, create files with Write, edit with Edit, search with Glob/Grep as needed.
5. **Validate success criteria** — review ALL checkboxes in the step's "Success Criteria" section, verify each is met, test your changes if testing is part of the criteria, and note the status of each.
6. **Report results** — summarize what you accomplished, which files were created/modified/deleted, which criteria were met, and any issues or blockers.

**Critical rules.** ✅ DO: execute THIS step only; complete ALL its success criteria; read context files before changing them; test if required; stop after completing the step. ❌ DO NOT: execute multiple steps; act on the rest of the plan beyond this one step; proceed to the next step automatically; skip success-criteria validation.

**When things fail:** explain the error clearly, stop (don't try alternative approaches beyond the step's scope), and report what succeeded and what failed so the user can decide whether to retry or adjust.

### 6. Verify Your Own Work

Before reporting completion, confirm you actually performed the work — do not claim success without it:

1. **Tool usage** — if you reached this point without using any tools (Read/Write/Edit/Bash), that is a red flag: you cannot have completed the step.
2. **File changes** — if you reported creating or modifying files, verify they exist (e.g. `ls -l <path>`) and have recent modification times.
3. If verification fails, do **not** report success. Show:
   ```
   ⚠️ Step not actually completed: files were reported as changed but do not exist on disk.

   Re-run the actions using the Write/Edit/Bash tools and verify again before reporting.
   ```
   Then redo the work for real.

### 7. Display Results and Next Step

After verification passes:

1. **Show structured output** using this format:
   ```
   ## Step Execution: <step-title>

   ### What I Did
   <concise summary of actions taken>

   ### Files Changed
   - Created: <file paths>
   - Modified: <file paths>
   - Deleted: <file paths>

   ### Commands Executed
   - <list of commands run>

   ### Success Criteria Status
   - [x] Criterion 1: <description> ✓
   - [x] Criterion 2: <description> ✓
   - [ ] Criterion 3: <description> ✗ (reason if failed)

   ### Result
   ✅ Step completed successfully
   (or ❌ Step failed: <reason>)

   ### Notes
   <any important observations or issues>
   ```

2. **Propagate discovered context.** Review what you learned while executing that is relevant for *subsequent* steps — file structures, API shapes, naming conventions, existing patterns, dependency versions, unexpected findings. If anything useful surfaced, list those items and ask the user whether to update the next steps in the plan to reference them. If nothing useful surfaced, skip this silently.

3. **Identify the next step** (do not execute it): parse the plan for all `### Step N:` headings and find the one after the current step.
   - If found: "Next: `/spec-buddy:execute <plan-file> <N+1>`"
   - If the current step was the last: "✓ All steps in plan completed!"

The user controls progression — never run the next step automatically.

## Error Handling

### Invalid Plan File
```
❌ Error: Plan file not found: <path>

Make sure the path is correct. Plans are typically in specs/plans/
```

### Invalid Step Number
```
❌ Error: Step 5 not found in plan

Available steps:
  - 1: Setup
  - 2: Implementation
  - 3: Tests

Usage: /spec-buddy:execute <plan-file> <step-number>
```

### Missing Arguments
```
❌ Error: Missing arguments

Usage: /spec-buddy:execute <plan-file> <step-number>

Example:
  /spec-buddy:execute specs/plans/add-feature.md 1
```

### Missing Specification Reference
If no spec reference is found in the plan's References section, work from the step's own references. No warning is shown to the user.

## Examples

### Example 1: Execute Setup Step
```
User: /spec-buddy:execute specs/plans/add-auth.md 1

→ Read specs/plans/add-auth.md
→ Find the specification reference in the References section
→ Extract the "### Step 1: Setup" section
→ Read the spec for context
→ Install dependencies, validate success criteria, report completion
→ Show: Next: /spec-buddy:execute specs/plans/add-auth.md 2
```

### Example 2: Execute Code Implementation Step
```
User: /spec-buddy:execute specs/plans/api-feature.md 3

→ Read the spec for context
→ Read the step details and file references
→ Create/modify code files
→ Run tests (if in success criteria)
→ Report files changed and criteria met
→ Suggest the next step
```

### Example 3: Step Not Found
```
User: /spec-buddy:execute plan.md 9

❌ Error: Step 9 not found in plan

Available steps:
  - 1: Setup Environment
  - 2: Install Dependencies
  - 3: Implement Feature
  - 4: Write Tests
  - 5: Update Docs
```

## Implementation Notes

- **Context + step**: read the spec (why) plus the full step content (what), then do the work yourself.
- **One step only**: strong emphasis on single-step execution throughout.
- **Validation**: check all success criteria before reporting completion.
- **Self-verification**: confirm you actually used tools and the reported files exist before claiming success.
- **Context propagation**: after a step, surface context useful for later steps and offer to update them.
- **User control**: no automatic progression — the user decides when to run the next step.

## Related Commands

- `/spec-buddy:new` - Create new specification
- `/spec-buddy:plan` - Generate implementation plan from spec

---

**Philosophy**: Execute one step at a time. The user reviews results and decides when to proceed. This ensures quality, control, and learning throughout the implementation process.
