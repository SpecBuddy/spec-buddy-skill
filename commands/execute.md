---
description: Execute one step from an implementation plan
---

# Execute Plan Step Command

Execute a single step from an implementation plan with full specification context.

## Usage

```
/spec-buddy:execute <plan-file> <step-number>
```

**Arguments:**
- `<plan-file>`: Path to the implementation plan markdown file
- `<step-number>`: Number of the step to execute (e.g., `1`, `2`, `3`)

**Example:**
```
/spec-buddy:execute .specs/plans/add-auth.md 1
```

## Instructions

When this command is invoked, follow these steps:

### 1. Parse Arguments

Extract plan file path and step number from `$ARGUMENTS`:
- Expected format: `<plan-file> <step-number>`
- Example: `.specs/plans/feature.md 1`

If arguments are missing or malformed:
- Show error: "Usage: /spec-buddy:execute <plan-file> <step-id>"
- Show example usage
- Stop execution

### 2. Read Plan File

Use the Read tool to load the plan file:
- If file not found, show error: "Plan file not found: <path>"
- List similar files in .specs/plans/ if available
- Stop execution

### 3. Extract Step Content

Find the requested step in the plan by its number:
- Scan for headings matching `### Step <N>:` (e.g., `### Step 1: Setup`)
- Extract all content from that heading until the next `###`-level heading or end of file

If step not found:
- Show error: "Step <N> not found in plan"
- List all available steps by finding all `### Step N:` headings in the plan
- Show format: "Available steps: 1 (Setup), 2 (Implementation), 3 (Tests)"
- Stop execution

### 4. Launch Step Executor Agent

Use the Task tool to launch the step-executor agent:

```
Task tool parameters:
- subagent_type: "step-executor"
- model: "sonnet"
- description: "Execute step <step-id> from <plan-file>"
- prompt: [see template below]
```

**Agent Prompt Template:**

```markdown
# Execute Implementation Plan Step

You are executing ONE SPECIFIC STEP from an implementation plan.

🎯 CRITICAL: Execute ONLY the step shown below. Do NOT execute other steps.

## Specification Context

<if the plan's References section contains a spec file path, write: "@file:<spec-path>">

<if no spec reference found in the plan, write: "(No specification provided - working with step context only)">

## Step to Execute

<paste the complete step section here, from its ### heading to the next ### heading>

---

Execute this step now, following your workflow instructions:
1. Understand the specification context by reading any @file: references above
2. Read any files or line ranges referenced in the step
3. Perform the actions listed in the step
4. Run any commands listed under Actions
5. Validate ALL success criteria
6. Report your results

Remember: Execute THIS step ONLY. Do not proceed to other steps.
```

### 5. Validate Agent Work

After the agent completes, verify it actually performed work:

1. **Check Tool Usage**: Look at the agent's response metadata
   - If `tool_uses: 0` or no tools were called, this is a red flag
   - Agent may have hallucinated completion without doing work

2. **Verify File Changes**: If agent reports creating/modifying files:
   - Use Bash `ls -l` to verify files exist
   - Check file modification timestamps are recent
   - If files don't exist, report error

3. **Validation Actions**:
   - If validation passes: Continue to step 6
   - If validation fails: Show error message:
     ```
     ⚠️ Validation Failed: Agent reported completion but did not perform actual work

     The agent claimed to create/modify files but they don't exist, or the agent
     didn't use any tools. This is a hallucination.

     Suggestions:
     - Retry the step: /spec-buddy:execute <plan-file> <step-id>
     - Check the agent transcript for details
     - Report this issue if it persists
     ```

### 6. Display Results

After validation passes:

1. **Show Agent Output**: The agent will provide structured output with its results

2. **Identify Next Step** (if available):
   - Parse the plan to find all `### Step N:` headings
   - Find the step after the current one
   - If found: "Next: `/spec-buddy:execute <plan-file> <N+1>`"
   - If current step was last: "✓ All steps in plan completed!"

## Error Handling

### Invalid Plan File
```
❌ Error: Plan file not found: <path>

Make sure the path is correct. Plans are typically in .specs/plans/
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
  /spec-buddy:execute .specs/plans/add-feature.md 1
```

### Missing Specification Reference

If no spec reference is found in the plan's References section, the agent prompt will note "(No specification provided - working with step context only)". No warning is shown to the user — the subagent gathers what it needs from the step's own `@file:` references.

## Examples

### Example 1: Execute Setup Step
```
User: /spec-buddy:execute .specs/plans/add-auth.md 1

→ Reads .specs/plans/add-auth.md
→ Finds specification reference in References section
→ Extracts "### Step 1: Setup" section
→ Launches step-executor agent with @file: reference to spec
→ Agent installs dependencies
→ Agent validates success criteria
→ Reports completion
→ Shows: Next: /spec-buddy:execute .specs/plans/add-auth.md 2
```

### Example 2: Execute Code Implementation Step
```
User: /spec-buddy:execute .specs/plans/api-feature.md implement-endpoint

→ Agent receives specification context
→ Agent reads step details and file references
→ Agent creates/modifies code files
→ Agent runs tests (if in success criteria)
→ Agent reports files changed and criteria met
→ Shows next step suggestion
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

### Example 4: Agent Hallucination Detected
```
User: /spec-buddy:execute .specs/plans/feature.md 2

→ Agent reports: "Created file commands/new-feature.md"
→ Validation checks: ls -l commands/new-feature.md
→ File not found!

⚠️ Validation Failed: Agent reported completion but did not perform actual work

The agent claimed to create commands/new-feature.md but the file doesn't exist.
This is a hallucination - the agent reported work without actually using tools.

Suggestions:
- Retry the step: /spec-buddy:execute .specs/plans/feature.md 2
- The retry will include explicit reminders to use the Write tool
```

## Implementation Notes

- **Context + Task**: Agent receives a `@file:` reference to the spec (why) and the full step content (what); the subagent reads files on its own
- **One Step Only**: Strong emphasis on single-step execution throughout
- **Validation**: Agent must check all success criteria before reporting completion
- **Post-Execution Validation**: Command validates agent actually used tools and created files
- **Hallucination Detection**: Catches cases where agent claims success without doing work
- **User Control**: No automatic progression - user decides when to run next step
- **Agent Tools**: step-executor has Read, Write, Edit, Bash, Glob, Grep tools
- **Model**: Uses sonnet for good balance of capability and speed

## Related Commands

- `/spec-buddy:new` - Create new specification
- `/spec-buddy:plan` - Generate implementation plan from spec (planned)

---

**Philosophy**: Execute one step at a time. User reviews results. User decides when to proceed. This ensures quality, control, and learning throughout the implementation process.