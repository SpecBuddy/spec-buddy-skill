---
description: Create an implementation plan for a feature or refactoring
---

# Create Implementation Plan Command

Generate a structured, executable implementation plan from a description, specification, or existing file.

## Usage

```
/spec-buddy:plan [description]
/spec-buddy:plan spec:.specs/path/to/spec.md
/spec-buddy:plan file:path/to/file.ext
```

**Arguments:**
- Plain text description: "Add user authentication with JWT"
- Specification reference: "spec:.specs/user-auth.md"
- File reference for refactoring: "file:src/legacy/UserService.ts"

## Instructions

When this command is invoked, follow these steps:

### 1. Validate Arguments

Check if `$ARGUMENTS` is provided:

If `$ARGUMENTS` is empty or unclear:
- Show error: "❌ Error: Missing arguments"
- Show usage:
  ```
  Usage: /spec-buddy:plan [description|spec:path|file:path]

  Examples:
    /spec-buddy:plan Add user authentication with JWT
    /spec-buddy:plan spec:.specs/user-auth.md
    /spec-buddy:plan file:src/legacy/UserService.ts
  ```
- Stop execution

### 2. Parse Input Mode

Analyze `$ARGUMENTS` to determine the mode:

**Mode 1: Description** (plain text, no markers)
- Example: "Add user authentication with JWT"
- User is providing a high-level feature description

**Mode 2: From Specification** (starts with `spec:`)
- Example: "spec:.specs/user-authentication.md"
- Extract path after "spec:"
- Verify file exists using Read tool
- If not found, show error with available specs

**Mode 3: From File** (starts with `file:`)
- Example: "file:src/legacy/UserService.ts"
- Extract path after "file:"
- Verify file exists using Read tool
- If not found, show error

### 3. Launch Plan Generator Agent

Use the Task tool to launch the specialized plan-generator agent:

```
Task tool parameters:
- subagent_type: "spec-buddy:plan-generator"
- model: "sonnet"
- description: "Generate implementation plan"
- prompt: [see template below]
```

**Agent Prompt Template:**

```markdown
# Generate Implementation Plan

You are a plan generation specialist. Create a detailed, executable implementation plan.

## Input

<Based on mode, include one of:>

**Mode: Description**
Feature description: <paste $ARGUMENTS>

**Mode: Specification**
Specification file: <paste spec file path>
<paste specification content from Read tool>

**Mode: File Refactoring**
File to refactor: <paste file path>
<paste file content from Read tool>

## Task

Generate a comprehensive implementation plan following the SpecBuddy format.

**Key Requirements:**
1. Analyze the codebase to understand project structure and conventions
2. Generate step-by-step plan with numbered `### Step N: Title` headings
3. Reference relevant files and line ranges using plain markdown (e.g., `See \`path/to/file#L10-L42\``)
4. Minimize code examples - prefer references to existing code
5. Create measurable success criteria for each step
6. Ensure proper step sequencing with dependencies
7. Save plan to `.specs/plans/[appropriate-name].md`

**Remember:**
- Trust the executing agent - don't include implementation code
- Reference existing patterns instead of showing code
- Only include declarations if absolutely necessary

Generate the plan now.
```

### 4. Display Results

After the agent completes, show the results to the user:

1. **Confirm creation:**
   ```
   ✓ Implementation plan created: .specs/plans/[filename].md
   ```

2. **Summarize the plan:**
   - Number of steps: [X]
   - Estimated effort: [Y hours/days]
   - Key milestones: [Brief description]

3. **Show first step command:**
   ```
   To start execution:
   /spec-buddy:execute .specs/plans/[filename].md [first-step-id]
   ```

4. **Offer guidance:**
   - "Review the plan and let me know if you'd like any adjustments"
   - "Ready to start? Run the command above to execute the first step"

## Examples

### Example 1: From Description

```bash
/spec-buddy:plan Add user authentication with JWT
```

The agent will:
- Analyze the codebase (detect Express.js, MongoDB, etc.)
- Generate a plan with setup, implementation, testing, docs steps
- Use @file references to existing patterns
- Minimize code examples
- Save to `.specs/plans/user-authentication.md`

### Example 2: From Specification

```bash
/spec-buddy:plan spec:.specs/api-redesign.md
```

The agent will:
- Read and analyze the specification
- Extract requirements
- Map requirements to implementation steps
- Create plan at `.specs/plans/api-redesign.md`

### Example 3: From File (Refactoring)

```bash
/spec-buddy:plan file:src/legacy/PaymentProcessor.ts
```

The agent will:
- Read and analyze the legacy file
- Identify refactoring opportunities
- Reference specific sections by file path and line ranges
- Create modernization plan
- Save to `.specs/plans/refactor-payment-processor.md`

## Error Handling

### Missing Arguments
```
❌ Error: Missing arguments

Usage: /spec-buddy:plan [description|spec:path|file:path]
```

### Specification Not Found
```
❌ Error: Specification file not found: .specs/feature.md

Available specifications:
  - .specs/user-auth.md
  - .specs/api-redesign.md
```

### File Not Found
```
❌ Error: File not found: src/legacy/Service.ts

Please check the path and try again.
```

## Related Commands

- `/spec-buddy:new` - Create a specification first
- `/spec-buddy:execute` - Execute steps from the plan

---

**Philosophy**: Plans are executable roadmaps with maximum clarity, minimum code. Trust the agent to figure out implementation details.
