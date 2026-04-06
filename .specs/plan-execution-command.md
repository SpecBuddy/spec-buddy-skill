# Plan Execution Command

**Status:** Draft
**Created:** 2026-02-12
**Last Updated:** 2026-02-12

## Overview

[Foo](specbuddy://explode)

The `/spec-buddy:execute` command executes individual steps from implementation plans by launching a specialized agent. The command reads a plan file, extracts the specification reference, finds the requested step, and passes both the spec and step to an agent that executes ONLY that one step.

## Goals

- Execute ONE step at a time from implementation plans
- Provide agent with both spec context and step details
- Track step completion
- Enable controlled, iterative development

## Non-Goals

- Automatic execution of multiple steps (Phase 2)
- Parallel step execution (Phase 2)
- Rollback functionality (Phase 2)

## Background

### Context

Plans created by `/spec-buddy:plan` are based on specifications and contain structured steps. Each step should be executed individually with full context of what's being built (from spec) and what this specific step should do.

### User Workflow

```
1. /spec-buddy:new feature description          → Create spec
2. /spec-buddy:plan spec:.specs/feature.md     → Create plan
3. Review plan
4. /spec-buddy:execute plan.md step-1           → Execute ONE step
5. Review results
6. /spec-buddy:execute plan.md step-2           → Execute next ONE step
7. Continue step by step
```

## Requirements

### Functional Requirements

#### FR1: Command Invocation
- **ID**: FR1
- **Priority**: P0
- **Description**: Execute ONE specific step from plan
- **Acceptance Criteria**:
  - `/spec-buddy:execute <plan-file> <step-number>` - Execute specific step
  - Validate plan file exists
  - Validate step exists
  - Clear error messages

#### FR2: Specification Reference Extraction
- **ID**: FR2
- **Priority**: P0
- **Description**: Find and read the specification file
- **Acceptance Criteria**:
  - Look for a spec file path in plan's References section
  - Read specification file
  - Pass spec content to agent for context
  - Handle missing spec gracefully

#### FR3: Step Extraction
- **ID**: FR3
- **Priority**: P0
- **Description**: Extract ONE step from plan
- **Acceptance Criteria**:
  - Find `### Step N:` heading by step number
  - Extract content until the next `###`-level heading or end of file
  - Include all content within the section

#### FR4: Agent Execution
- **ID**: FR4
- **Priority**: P0
- **Description**: Launch agent to execute ONE step
- **Acceptance Criteria**:
  - Use Task tool
  - Pass specification for context
  - Pass ONE step to execute
  - Explicitly instruct: execute THIS step ONLY
  - Allow necessary tools (Read, Write, Edit, Bash)
  - Use sonnet model by default

#### FR5: Execution Feedback
- **ID**: FR5
- **Priority**: P0
- **Description**: Show clear results
- **Acceptance Criteria**:
  - Display what was done
  - Show success criteria status
  - Indicate success/failure
  - Suggest next step

### Non-Functional Requirements

#### NFR1: Simplicity
- **Priority**: P0
- **Description**: Keep command simple
- **Criteria**: Minimal logic, Claude handles execution

#### NFR2: User Control
- **Priority**: P0
- **Description**: User controls each step
- **Criteria**: Explicit execution, no auto-advancement

#### NFR3: Clarity
- **Priority**: P0
- **Description**: Make execution scope clear
- **Criteria**: Agent knows it's executing ONE step only

## Technical Design

### Architecture

```
User: /spec-buddy:execute plan.md <step-number>
    ↓
Command (commands/execute.md)
    ↓
Read plan file
    ├─ Find spec file path in References section
    ├─ Read specification file
    └─ Find step by "### Step N:" heading
    ↓
Task tool → Launch agent
    ├─ Pass specification (context)
    ├─ Pass ONE step section (to execute)
    └─ Explicitly: execute THIS step ONLY
    ↓
Agent executes THIS ONE step
    ├─ Understands overall goal (from spec)
    ├─ Executes this specific step
    ├─ Validates success criteria for THIS step
    └─ Reports results
    ↓
User reviews → proceeds to next step manually
```

### Command Implementation

Create `commands/execute.md`:

```yaml
---
description: Execute one step from an implementation plan
---
```

**Instructions for Claude:**

1. **Parse Arguments:**
   - Expect: `<plan-file> <step-number>`
   - Example: `.specs/plans/feature.md 1`

2. **Read Plan File:**
   - Use Read tool to load plan
   - If not found, show error

3. **Find Specification:**
   - Look in plan's "References" section for a spec file path
   - Read specification file
   - If not found, continue without spec (warn user)

4. **Find Step:**
   - Search for `### Step <N>:` heading
   - Extract until the next `###` heading or end of file
   - If not found, list available steps

5. **Launch Agent:**
   ```javascript
   Task tool with:
   - subagent_type: "general-purpose"
   - model: "sonnet"
   - description: "Execute step <N> from plan"
   - prompt: [see template below]
   ```

6. **Agent Prompt Template:**
   ```markdown
   You are executing ONE SPECIFIC STEP from an implementation plan.

   IMPORTANT: Execute ONLY the step specified below. Do NOT attempt to execute other steps or the entire plan.

   ## Overall Context (from Specification)

   <paste specification content here - so agent understands the big picture>

   ## YOUR TASK: Execute THIS ONE Step

   <paste the step section here, from its ### heading to the next ### heading>

   ## Instructions

   1. **Understand Context**: Read the specification to understand the overall goal
   2. **Focus on THIS Step**: You are executing ONLY the step shown above
   3. **Review Context**: Read files referenced in the step
   4. **Perform Actions**: Do what the Actions section describes
   5. **Execute Commands**: Run commands listed under Actions
   6. **Make Changes**: Edit/create files as needed
   7. **Validate**: Check ALL success criteria for THIS step
   8. **Report**: Summarize what you did and confirm criteria met

   ## Critical Rules

   - Execute THIS step ONLY, not other steps from the plan
   - Complete ALL success criteria listed in this step
   - If something fails, explain clearly and stop
   - Don't proceed to next steps automatically

   Begin executing THIS step now.
   ```

7. **Display Results:**
   - Show agent's output
   - Indicate success/failure
   - Show which success criteria were met
   - Suggest next step: `/spec-buddy:execute <plan-file> <next-step-number>`

### Example

**Plan file** (`.specs/plans/add-auth.md`):
```markdown
# Implementation Plan: User Authentication

...

## Implementation Steps

### Step 1: Install Dependencies
Install authentication libraries.

**Actions:**
- Run: `npm install jsonwebtoken bcrypt`

**Success Criteria:**
- [ ] jsonwebtoken installed
- [ ] bcrypt installed

### Step 2: Create User Model
...

## References
- `.specs/user-authentication.md`
```

**User runs:**
```bash
/spec-buddy:execute .specs/plans/add-auth.md 1
```

**Command does:**
1. Reads `.specs/plans/add-auth.md`
2. Finds `.specs/user-authentication.md` in References
3. Reads `.specs/user-authentication.md` (for context)
4. Extracts `### Step 1:` section content
5. Launches agent with:
   - Full specification (context)
   - Step section (task)
   - Explicit instruction: execute THIS step ONLY

**Agent does:**
1. Reads spec (understands auth is being built)
2. Reads step (knows to install dependencies)
3. Runs `npm install jsonwebtoken bcrypt`
4. Checks success criteria
5. Reports: "Installed jsonwebtoken and bcrypt successfully"

**User then runs:**
```bash
/spec-buddy:execute .specs/plans/add-auth.md 2
```

And continues step by step.

## Edge Cases

### EC1: Step Not Found
- **Handling**: List all available steps (numbers and titles) from plan

### EC2: Spec Not Found
- **Handling**: Warn but continue (agent has less context)

### EC3: Malformed Step
- **Handling**: Error message, suggest fixing plan

### EC4: No Arguments
- **Handling**: Show usage example

### EC5: Agent Failure
- **Handling**: Show error, allow retry same step

## Security

- Agent runs with user permissions
- Follows Claude Code safety rules
- User controls each step execution
- No automatic multi-step execution

## Testing Strategy

### Test 1: Simple Step
```bash
/spec-buddy:execute test-plan.md 1
```
Expected: Agent installs dependencies, checks criteria

### Test 2: Code Step
```bash
/spec-buddy:execute feature-plan.md 2
```
Expected: Agent writes code for API, validates

### Test 3: Sequential Steps
```bash
/spec-buddy:execute plan.md 1
# review...
/spec-buddy:execute plan.md 2
# review...
/spec-buddy:execute plan.md 3
```
Expected: Each step executes independently

### Test 4: Without Spec
Plan with no spec reference in References section
Expected: Warning, continues without spec context

## Open Questions

1. **Status tracking**: Mark completed steps in plan?
2. **Dependency checking**: Verify previous steps done?
3. **Auto-suggest**: Show next step ID automatically?
4. **Batch mode**: Execute multiple steps with confirmation?

## Future Enhancements

### Phase 2
- Mark completed steps: `[✓ 2026-02-12]`
- Auto-find next pending step
- Execute all: `/spec-buddy:execute plan.md --all` (with confirmations)

### Phase 3
- Check dependencies before execution
- Rollback support
- Parallel execution of independent steps
- Integration with git (commit per step)

## References

- `.specs/implementation-plan-command.md` - Plan creation
- `.specs/spec-creation-command.md` - Spec creation
- `.specs/concept.md` - SpecBuddy concept
- `CLAUDE.md` - Plugin architecture
