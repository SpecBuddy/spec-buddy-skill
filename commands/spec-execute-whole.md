---
description: Execute a specification file directly — implement all requirements in one pass without a plan
---

# Execute Specification Command

Read a specification file and implement all its requirements in a single pass, without generating or requiring a step plan.

## Usage

```
/spec-buddy:spec-execute-whole <spec-file>
```

**Arguments:**
- `<spec-file>`: Path to the specification markdown file (e.g., `.specs/my-feature.md`)

**Example:**
```
/spec-buddy:spec-execute-whole .specs/add-auth.md
```

## Instructions

When this command is invoked, follow these steps:

### 1. Parse Arguments

Extract the spec file path from `$ARGUMENTS`:
- Expected format: `<spec-file>`
- Example: `.specs/my-feature.md`

If the argument is missing:
- Show error: "Usage: /spec-buddy:spec-execute-whole <spec-file>"
- Show example usage
- Stop execution

### 2. Read the Specification File

Use the Read tool to load the spec file:
- If file not found, show error: "Spec file not found: <path>"
- List similar files in `.specs/` if available
- Stop execution on error

### 3. Understand the Specification

Analyse the full spec content:
- Identify the feature goal and all functional requirements
- Note technical design decisions, constraints, and any referenced files or APIs
- Identify any open questions that might block implementation — if critical, surface them before proceeding

### 4. Implement the Specification

You perform the work directly — there is no separate sub-agent to dispatch to.

IMPORTANT: Load the `intellij-plugin-guidelines` skill before writing any IntelliJ Platform code.

1. Read the specification file thoroughly.
2. Understand the full scope: goals, requirements, technical design, and constraints.
3. Implement ALL requirements described in the spec:
   - Create or modify every file that the spec calls for
   - Follow all technical design decisions stated in the spec
   - Respect existing code conventions found in the project
4. Validate your work:
   - Verify that every stated requirement is satisfied
   - Run any commands listed in the spec (tests, build, lint) and fix failures
   - Check that no existing behaviour is broken

### 5. Display Results

1. List every file created or modified.
2. Confirm which requirements are satisfied and note anything skipped and why.
3. Confirm: "Spec implemented. Review changes with `git diff`."

## Error Handling

### Missing Argument
```
Error: Missing argument

Usage: /spec-buddy:spec-execute-whole <spec-file>

Example:
  /spec-buddy:spec-execute-whole .specs/add-feature.md
```

### Spec File Not Found
```
Error: Spec file not found: <path>

Make sure the path is correct. Specs are typically in .specs/
```

## Examples

### Example 1: Implement a feature spec
```
User: /spec-buddy:spec-execute-whole .specs/dark-mode.md

→ Reads .specs/dark-mode.md
→ Understands requirements: toggle, persistence, theme tokens
→ Creates/modifies source files directly
→ Runs tests, fixes failures
→ Reports: 4 files modified, all requirements satisfied
→ "Spec implemented. Review changes with git diff."
```

### Example 2: Spec not found
```
User: /spec-buddy:spec-execute-whole .specs/missing.md

Error: Spec file not found: .specs/missing.md

Available specs:
  .specs/auth.md
  .specs/dark-mode.md
```

## Implementation Notes

- **No plan required**: Read the spec directly and implement without an intermediate plan file.
- **Single pass**: Implement all requirements in one pass.
- **IntelliJ Plugin code**: Load `intellij-plugin-guidelines` before writing any IntelliJ Platform code.
- **User control**: No automatic follow-up — user reviews `git diff` and decides next actions.

## Related Commands

- `/spec-buddy:spec-new` - Create a new specification file
- `/spec-buddy:spec-plan` - Generate a step-by-step plan from a spec
- `/spec-buddy:execute` - Execute a single step from an existing plan

---

**Philosophy**: Sometimes a spec is small and clear enough that a plan is overhead. This command lets you go straight from spec to code.