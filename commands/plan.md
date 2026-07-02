---
description: Create an implementation plan for a feature or refactoring
---

# Create Implementation Plan Command

Generate a structured, executable implementation plan from a description, specification, or existing file. You perform plan generation **directly** — there is no sub-agent to dispatch to.

## Usage

```
/spec-buddy:plan [description]
/spec-buddy:plan spec:specs/path/to/spec.md
/spec-buddy:plan file:path/to/file.ext
```

**Arguments:**
- Plain text description: "Add user authentication with JWT"
- Specification reference: "spec:specs/user-auth.md"
- File reference for refactoring: "file:src/legacy/UserService.ts"

## Instructions

When this command is invoked, follow these steps.

### 1. Validate Arguments

If `$ARGUMENTS` is empty or unclear:
- Show error: "❌ Error: Missing arguments"
- Show usage:
  ```
  Usage: /spec-buddy:plan [description|spec:path|file:path]

  Examples:
    /spec-buddy:plan Add user authentication with JWT
    /spec-buddy:plan spec:specs/user-auth.md
    /spec-buddy:plan file:src/legacy/UserService.ts
  ```
- Stop execution

### 2. Parse Input Mode

Analyze `$ARGUMENTS` to determine the mode:

**Mode 1: Description** (plain text, no markers) — a high-level feature description.

**Mode 2: From Specification** (starts with `spec:`) — extract the path after `spec:`, verify it exists with the Read tool. If not found, show an error listing available specs in `specs/`.

**Mode 3: From File** (starts with `file:`) — extract the path after `file:`, verify it exists with the Read tool. If not found, show an error.

### 3. Generate the Implementation Plan

You are the implementation plan generation specialist. Analyze the input and produce a detailed, executable plan in plain markdown, following the workflow below. Write the finished plan to `specs/plans/[filename].md` (see [File Naming](#file-naming)).

#### Core Responsibilities

1. Analyze project structure and conventions.
2. Generate a step-by-step implementation plan in plain markdown.
3. Reference files and line ranges in plain prose.
4. Sequence steps with proper dependencies.
5. Define measurable success criteria.

#### Key Principle — Minimize Code Examples, Maximize References

**CRITICAL:** Plans should contain minimal code examples. Trust the executing agent to figure out implementation details.

**Prefer references over code:**
- Reference entire files: ``See `src/services/AuthService.ts` ``
- Reference specific sections: ``See `src/api/handlers.ts#L45-L67` ``
- Instead of showing how to implement a class, reference a similar existing one:
  ```
  Create UserService following the pattern in `src/services/AuthService.ts`
  ```

**Code example guidelines:**
- **NO IMPLEMENTATIONS** — never include full code implementations in plans.
- **Declarations only** — only include function/class signatures if absolutely necessary.
- **99% rule** — only include real code if you are 99% confident the agent cannot handle it without the code.
- **Reference existing patterns** — point at existing code that demonstrates the pattern.
- Avoid showing schema definitions, service methods, or utility functions — describe fields and behavior in prose, reference a similar file for structure.

**When code is acceptable:** configuration snippets (JSON, YAML) that must be exact; complex, error-prone regexes; critical algorithms where precision is essential. Even then, keep it minimal.

**Example.** ❌ Bad — too much code:
```markdown
**Actions:**
1. Create User model:
   ```typescript
   const userSchema = new Schema<IUser>({
     email: { type: String, required: true, unique: true },
     ...
   });
   ```
```
✅ Good — references and minimal guidance:
```markdown
**Actions:**
1. Create `src/models/User.ts`
   - Follow the schema pattern in `src/models/Product.ts`
   - Include fields: email (unique), password (hashed), createdAt
```

#### Workflow

**a. Gather context.** *Spec-first approach:* if a spec, reference file, or explicit context file is provided, read it in full first. The spec is the primary source of truth for which files, patterns, and constraints to consider. Extract all file references, architectural decisions, and constraints from it before exploring the codebase. *Fallback — codebase exploration:* only if the spec does not supply the needed context, explore the codebase directly with **Glob** (project structure, file types, test locations), **Read** (`package.json`, `tsconfig.json`, key entry points), and **Grep** (existing patterns, similar features, testing frameworks).

**b. Generate plan structure.** Create a comprehensive plan with these sections: Overview (2–3 sentences), Goals (3–5 primary objectives), Scope (in/out of scope), Prerequisites (checkboxes), Implementation Steps (below), Validation Checklist, Risks and Mitigations, References.

**c. Generate implementation steps.** Each step follows this format:

```markdown
### Step N: Descriptive Title

[2-3 sentences describing what this step accomplishes and why]

**Context:**
- See `path/to/file/for/context`
- See `path/to/file#L10-L42`

**Actions:**
1. [Specific action - use references, not code]
2. [Another action]
   - Run: `command-to-execute`
3. [Reference existing patterns extensively]

**Success Criteria:**
- [ ] [Measurable, verifiable criterion]
- [ ] [Another criterion]
- [ ] [3-5 criteria per step]

**Dependencies:** [step numbers or "none"]
```

*Mention relevant skills.* When generating steps, if there are skills (slash commands, agent capabilities, installed plugins, etc.) relevant to a particular step, mention them in the step description so the executor knows which tools to leverage — e.g. "This step can use `/spec-buddy:connekt` for HTTP testing" or "Consider using the `crud-rest-controller` skill for the endpoints." If none are relevant, omit the mention.

*Step sequencing:* (1) setup/prerequisites, (2) foundation (base files, models, types), (3) core implementation, (4) error handling and edge cases, (5) testing, (6) documentation.

*Dependency rules:* each step lists dependencies by step number; dependencies must be on earlier steps (no cycles); steps without dependencies can run in parallel; use "none" if no dependencies.

**d. File and command references.** File references are plain backtick paths — to read for context (``See `src/models/User.ts` ``), to create/modify (``Create `src/auth/jwt.ts` ``), or line ranges (``See `src/config.ts#L45-L67` ``). Commands are listed under Actions — installation (``Run: `npm install express` ``), testing (``Run: `npm test` ``), build (``Run: `npm run build` ``).

**e. Success criteria.** Must be specific, measurable, verifiable by an agent, and testable programmatically. Good: "File `src/auth/jwt.ts` exists and exports `signToken`, `verifyToken`." Bad (too vague): "Code works."

#### Step Granularity

**Default to coarse-grained steps.** A step may freely touch as many files as needed. Do not create small steps just to track progress — the developer will sub-divide a step themselves if it turns out to need more detail.

**Steps are high-level, not granular. Refinement happens during execution, not during planning.** A step describes a coherent unit of work, not a per-keystroke checklist. Do not pre-decompose a step into micro-actions in the plan — the executor (agent or developer) discovers the right decomposition while doing the work, with the actual code in front of them. A plan is a roadmap, not a script. If a step turns out to be too vague at execution time, the developer will ask to break it down then — that path is cheap. The reverse (un-fragmenting a plan padded with granular steps) is expensive and noisy, and is the failure mode this guidance exists to prevent.

**Lean toward underestimating complexity, not overestimating it.** When sizing the task and choosing a row in the norms table below, pick the smaller category if you are torn between two. Underestimating produces a lean plan that the developer can grow on demand; overestimating produces a bloated plan full of defensive steps for problems that never materialize.

**Step count norms by task size.** The numbers below are upper bounds, not targets. Aim for fewer steps than the max whenever possible.

| Task size  | Examples                                                                                          | Max step count                                                           |
|------------|---------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------|
| Trivial    | Config tweak, single-function fix, doc edit, one-line change                                      | **1**                                                                    |
| Small      | New file, single endpoint, simple addition, localized refactor                                    | **1–2**                                                                  |
| Medium     | New module spanning a few files, multi-file refactor, new feature reusing existing infrastructure | **2–4**                                                                  |
| Large      | New subsystem, cross-cutting change, feature touching multiple layers                             | **4–8**                                                                  |
| Very large | New service, major architectural change, multi-subsystem rewrite                                  | **8–15** — beyond 15, split into sub-features and produce multiple plans |

A plan that exceeds the upper bound for its category is a signal to either (a) merge adjacent steps that share a coherent unit of work, or (b) split the work into separate plans. It is **not** a signal to keep the step count and add more detail per step.

**Do not create a step for:** a single command invocation with no decision points (fold into an adjacent step's Actions); "verify"/"review" tasks already covered by the previous step's Success Criteria; setup the developer has clearly already done; mechanical documentation follow-ups (fold into the implementation step).

**Anti-pattern: editing the same file in two different steps without a justified reason.** If both edits belong together, they belong in one step. Split a file's edits across steps **only** when a hard dependency makes it necessary (e.g. a schema change must precede a migration before consuming code can be written).

**Prefer step boundaries where the code compiles.** Each step should leave the codebase buildable. If a change breaks callers — renaming a method, changing a signature, removing an exported symbol — update all call sites in the same step. Do not defer the fan-out to a later step just to make the initial step smaller.

- ❌ Violation — Step 1: change signature of `UserService.findById` to return `Optional<User>` (leaves every caller broken); Step 2: update all callers (inherits a broken build).
- ✅ Correct — Step 1: change signature of `UserService.findById` to return `Optional<User>` **and** update all call sites (`UserController`, `AuthService`, `AdminService`) — build passes.

An exception is allowed only when compilation between steps is genuinely impossible (e.g. an intermediate state requires a generated file or a migration) — and in that case, state the reason explicitly in the step description.

Step size should reflect a **coherent unit of work**, not a time estimate.

#### File Naming

Generate the filename from the feature: extract key terms, convert to kebab-case, keep concise (2–5 words). Examples: "Add user authentication with JWT" → `user-authentication.md`; "Refactor API error handling" → `api-error-handling.md`. Path: `specs/plans/[filename].md`.

#### Quality Checklist

Before finalizing:
- [ ] All steps have numbered headings (`### Step N: Title`).
- [ ] All steps have clear success criteria (3–5 each).
- [ ] Dependencies form a valid DAG (no cycles).
- [ ] File references use correct paths.
- [ ] Commands are appropriate for the project.
- [ ] Prerequisites clearly stated.
- [ ] Risks and mitigations identified.
- [ ] **Minimal code examples** (references preferred).
- [ ] Relevant skills mentioned in step descriptions where applicable.

### 4. Display Results

After writing the plan file, show the results to the user:

1. **Confirm creation:** `✓ Implementation plan created: specs/plans/[filename].md`
2. **Summarize the plan:** number of steps, key milestones.
3. **Show the first step command:**
   ```
   To start execution:
   /spec-buddy:execute specs/plans/[filename].md 1
   ```
4. **Offer guidance:** invite review/adjustments, and point at the execute command above.

## Examples

### Example 1: From Description
```bash
/spec-buddy:plan Add user authentication with JWT
```
Analyze the codebase (detect Express.js, MongoDB, etc.), generate a plan with setup/implementation/testing/docs steps, reference existing patterns, minimize code, and save to `specs/plans/user-authentication.md`.

### Example 2: From Specification
```bash
/spec-buddy:plan spec:specs/api-redesign.md
```
Read and analyze the specification, extract requirements, map them to implementation steps, and create the plan at `specs/plans/api-redesign.md`.

### Example 3: From File (Refactoring)
```bash
/spec-buddy:plan file:src/legacy/PaymentProcessor.ts
```
Read and analyze the legacy file, identify refactoring opportunities, reference specific sections by file path and line range, and save the modernization plan to `specs/plans/refactor-payment-processor.md`.

## Error Handling

### Missing Arguments
```
❌ Error: Missing arguments

Usage: /spec-buddy:plan [description|spec:path|file:path]
```

### Specification Not Found
```
❌ Error: Specification file not found: specs/feature.md

Available specifications:
  - specs/user-auth.md
  - specs/api-redesign.md
```

### File Not Found
```
❌ Error: File not found: src/legacy/Service.ts

Please check the path and try again.
```

### Ambiguous Description
Ask clarifying questions: which component? What defines success? What is the current baseline?

### Large Scope (>15 steps)
The plan exceeds the "Very large" upper bound. Suggest breaking the work into sub-features and producing multiple related plans rather than one oversized plan.

## Related Commands

- `/spec-buddy:new` — Create a specification first
- `/spec-buddy:execute` — Execute steps from the plan

---

**Philosophy**: Plans are executable roadmaps with maximum clarity, minimum code. Reference existing code extensively. Trust the executing agent to figure out implementation details.
