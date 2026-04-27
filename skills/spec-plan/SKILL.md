---
name: plan
description: Generate a structured, executable implementation plan from a feature description, an existing specification file under `.specs/`, or a source file targeted for refactoring. Saves the plan to `.specs/plans/<name>.md` with numbered steps, success criteria, and dependencies.
triggers:
  - "create an implementation plan"
  - "plan this feature"
  - "break this spec into steps"
  - "generate a plan from this specification"
  - "plan a refactor of this file"
  - "turn this spec into an implementation plan"
---

# Create Implementation Plan

Generate a structured, executable implementation plan from one of three input modes:
1. **Description mode** — a plain-text feature description.
2. **Spec mode** — a path to an existing specification file (typically under `.specs/`).
3. **File mode** — a path to a source file targeted for refactoring.

You perform plan generation directly. There is no separate sub-agent to dispatch to.

## Input Elicitation

Determine the input mode from what the user said:
- If they pasted or wrote a feature description, use **description mode**.
- If they referenced a specification file (e.g. `.specs/user-auth.md`), use **spec mode**.
- If they referenced a source file to refactor (e.g. `src/legacy/UserService.ts`), use **file mode**.

If the request is empty or genuinely ambiguous, ask the user which of the three inputs they want to use, and for the path or description, then continue.

For spec mode and file mode, verify the referenced file exists by reading it. If the path does not exist, tell the user and offer the closest matches in `.specs/` (for spec mode) or ask for the correct path (for file mode).

---

## Plan Generation Workflow

You are the implementation plan generation specialist. Your role is to analyze the input and produce a detailed, executable implementation plan in plain markdown.

### Core Responsibilities

1. Analyze project structure and conventions.
2. Generate step-by-step implementation plans in plain markdown.
3. Reference files and line ranges in plain prose.
4. Sequence steps with proper dependencies.
5. Define measurable success criteria.

### Key Principles

#### Minimize Code Examples, Maximize References

**CRITICAL:** Plans should contain minimal code examples. Trust the executing agent to figure out implementation details.

**Prefer references over code:**
- Reference entire files: ``See `src/services/AuthService.ts` ``
- Reference specific sections: ``See `src/api/handlers.ts#L45-L67` ``
- Example: instead of showing how to implement a class, reference similar existing classes:

  ```
  Create UserService following the pattern in `src/services/AuthService.ts`
  ```

**Code example guidelines:**
- **NO IMPLEMENTATIONS** — never include full code implementations in plans.
- **Declarations only** — only include function/class signatures if absolutely necessary.
- **99% rule** — only include real code if you are 99% confident the agent cannot handle it without the code.
- **Reference existing patterns** — point at existing code that demonstrates the pattern.
- Avoid showing schema definitions, service methods, or utility functions — describe fields and behavior in prose, reference a similar file for structure.

**When code is acceptable:**
- Configuration snippets (JSON, YAML) that must be exact.
- Complex regex patterns that are error-prone.
- Critical algorithms where precision is essential.
- Even then, keep it minimal — just the essential parts.

**Example:**

Bad — too much code:

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

Good — references and minimal guidance:

```markdown
**Actions:**
1. Create `src/models/User.ts`
   - Follow the schema pattern in `src/models/Product.ts`
   - Include fields: email (unique), password (hashed), createdAt
```

### 1. Analyze Input Mode

Determine if input is description mode, spec mode, or file mode (see Input Elicitation above).

### 2. Gather Context

**Spec-first approach:** if a spec, reference file, or explicit context file is provided, read it in full first. The spec is the primary source of truth for which files, patterns, and constraints to consider. Extract all file references, architectural decisions, and constraints from it before exploring the codebase.

**Fallback — codebase exploration:** only if the spec does not supply the needed context, explore the codebase directly:
- **Glob** — discover project structure, file types, test locations.
- **Read** — examine `package.json`, `tsconfig.json`, key entry points.
- **Grep** — find existing patterns, similar features, testing frameworks.

### 3. Generate Plan Structure

Create a comprehensive plan with these sections:
- Overview (2–3 sentences)
- Goals (3–5 primary objectives)
- Scope (in / out of scope)
- Prerequisites (checkboxes)
- Implementation Steps (see below)
- Validation Checklist
- Risks and Mitigations
- References

### 4. Generate Implementation Steps

> **CRITICAL — `<!-- specbuddy:step -->` comment is MANDATORY.**
>
> See [Annotation Behavior](#annotation-behavior) for the complete rules. In summary: `<!-- specbuddy:step -->` must appear on the line immediately after every `### Step N:` heading — no exceptions, no blank line between. Missing this annotation causes the step to be silently skipped.

Each step follows this format:

```markdown
### Step N: Descriptive Title
<!-- specbuddy:step -->

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

#### Mention Relevant Skills

When generating steps, if there are skills (slash commands, agent capabilities, installed plugins, etc.) that are relevant to a particular step, mention them in the step description. This helps the executor know which tools to leverage.

For example:
- "This step can use the `connekt` skill for HTTP testing."
- "Consider using the `crud-rest-controller` skill for generating the endpoints."

If no skills are relevant, simply omit the mention — do not force it.

#### Step Sequencing

1. Setup / prerequisites (dependencies, directories).
2. Foundation (base files, models, types).
3. Core implementation.
4. Error handling and edge cases.
5. Testing.
6. Documentation.

#### Dependency Rules

- Each step lists dependencies by step number.
- Dependencies must be on earlier steps (no cycles).
- Steps without dependencies can run in parallel.
- Use "none" if no dependencies.

### 5. File and Command References

**File references** — plain backtick paths:
- Files to read for context: ``See `src/models/User.ts` ``
- Files to create or modify: ``Create `src/auth/jwt.ts` ``
- Line ranges: ``See `src/config.ts#L45-L67` ``

**Commands** — listed under Actions:
- Installation: ``Run: `npm install express` ``
- Testing: ``Run: `npm test` ``
- Build: ``Run: `npm run build` ``

### 6. Success Criteria Guidelines

**Must be:**
- Specific and measurable.
- Verifiable by an agent.
- Testable programmatically.

**Good examples:**
- "File `src/auth/jwt.ts` exists and exports `signToken`, `verifyToken` functions."
- "All tests in `tests/auth.test.ts` pass."
- "Server starts without errors and responds to `GET /health`."

**Bad examples (too vague):**
- "Code works."
- "Feature is implemented."

### 7. Step Granularity

**Default to coarse-grained steps.** A step may freely touch as many files as needed. Do not create small steps just to track progress — the developer will sub-divide a step themselves if it turns out to need more detail.

**Steps are high-level, not granular. Refinement happens during execution, not during planning.** A step describes a coherent unit of work, not a per-keystroke checklist. Do not pre-decompose a step into micro-actions in the plan — the executor (agent or developer) discovers the right decomposition while doing the work, with the actual code in front of them. A plan is a roadmap, not a script. If a step turns out to be too vague at execution time, the developer will ask to break it down then — that path is cheap. The reverse (un-fragmenting a plan padded with granular steps) is expensive and noisy, and is the failure mode this guidance exists to prevent.

**Lean toward underestimating complexity, not overestimating it.** When sizing the task and choosing a row in the norms table below, pick the smaller category if you are torn between two. Assume the project is more regular and the executor more capable than your worst-case reading suggests. Underestimating produces a lean plan that the developer can grow on demand; overestimating produces a bloated plan full of defensive steps for problems that never materialize. The cost of being wrong on the low side is one "please split this step" message; the cost of being wrong on the high side is a plan that nobody wants to read.

**Step count norms by task size.** The numbers below are upper bounds, not targets. Aim for fewer steps than the max whenever possible — if the developer cannot follow a step, they will ask to split it. The reverse (a plan with too many tiny steps) is harder to recover from and the failure mode this guidance exists to prevent.

| Task size  | Examples                                                                                          | Max step count                                                           |
|------------|---------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------|
| Trivial    | Config tweak, single-function fix, doc edit, one-line change                                      | **1**                                                                    |
| Small      | New file, single endpoint, simple addition, localized refactor                                    | **1–2**                                                                  |
| Medium     | New module spanning a few files, multi-file refactor, new feature reusing existing infrastructure | **2–4**                                                                  |
| Large      | New subsystem, cross-cutting change, feature touching multiple layers                             | **4–8**                                                                  |
| Very large | New service, major architectural change, multi-subsystem rewrite                                  | **8–15** — beyond 15, split into sub-features and produce multiple plans |

A plan that exceeds the upper bound for its category is a signal to either (a) merge adjacent steps that share a coherent unit of work, or (b) split the work into separate plans. It is **not** a signal to keep the step count and add more detail per step.

**Do not create a step for:**
- A single command invocation that has no decision points (fold into the preceding or following step's Actions).
- "Verify" or "review" tasks that are already covered by the previous step's Success Criteria.
- Setup that the developer has clearly already done (don't add `npm install` if the project is already running).
- Documentation updates that are mechanical follow-ups to the implementation (fold into the implementation step).

**Anti-pattern: editing the same file in two different steps without a justified reason.** If both edits belong together, they belong in one step.

Split a file's edits across steps **only** when a hard dependency makes it necessary — for example, when a schema change must be followed by a migration before the consuming code can be written.

**Prefer step boundaries where the code compiles.** Each step should leave the codebase in a buildable state. If a change breaks callers — renaming a method, changing a signature, removing an exported symbol — update all call sites in the same step. Do not defer the fan-out to a later step just to make the initial step smaller. A step that leaves the project with compile errors forces the next step to inherit broken state and obscures whether its own changes are correct.

**Example of a violation:**
- Step 1: Change signature of `UserService.findById` to return `Optional<User>` — leaves every caller broken.
- Step 2: Update all callers of `findById` — inherits a broken build.

**Correct split:**
- Step 1: Change signature of `UserService.findById` to return `Optional<User>` and update all call sites (`UserController`, `AuthService`, `AdminService`) — build passes.

An exception is allowed only when compilation between steps is genuinely impossible (e.g. the intermediate state requires a generated file or a migration) — and in that case, state the reason explicitly in the step description.

**Example of a justified split:**
- Step 1: Update `src/models/User.ts` to add the `role` field — success criterion: migration script generated.
- Step 2: Run `npm run db:migrate` — success criterion: migration applied to the database.
- Step 3: Update `src/routes/user.ts` to use the new `role` field — success criterion: route tests pass.

Without the migration step between 1 and 3, step 3 would fail at runtime. That dependency justifies the split. If no such dependency exists, keep both edits in one step.

Step size should reflect a **coherent unit of work**, not a time estimate.

## Annotation Behavior

Two annotation strings are used by the SpecBuddy harness. They must appear exactly as specified below — no attributes, no extra spaces inside the tag, no variations of any kind. Any deviation makes the annotation unrecognized.

### Rule 1 — Exact syntax, no attributes

The only valid annotation forms are:

- `<!-- specbuddy:step -->`
- `<!-- specbuddy:create-plan -->`

Do not add IDs, attributes, extra whitespace inside the delimiters, or any other modification. Write them exactly as shown above.

### Rule 2 — `<!-- specbuddy:step -->` placement

Every `### Step N:` heading must be followed immediately — on the very next line, with no blank line between — by `<!-- specbuddy:step -->`. This annotation is the harness's sole mechanism for locating executable steps. A missing annotation causes the step to be silently skipped and never executed.

### Rule 3 — `<!-- specbuddy:create-plan -->` lifecycle

When you find `<!-- specbuddy:create-plan -->` in a document (typically at the end of a spec produced by the `spec-new` skill), it signals "generate the plan here." After generating the plan content, the annotation line itself must be deleted — the plan content takes its place. The annotation must not appear anywhere in the finished plan file.

### Rule 4 — Preserve existing `<!-- specbuddy:step -->` annotations

When editing or refining an existing plan that already contains `<!-- specbuddy:step -->` annotations, those annotations must not be moved, removed, or modified. Only add the annotation to newly created steps; leave all existing annotations exactly as they are.

### Rule 5 — Do not touch unknown annotations

If the document contains HTML comment annotations that are not `<!-- specbuddy:step -->` or `<!-- specbuddy:create-plan -->`, leave them exactly as they are. Do not remove, modify, reformat, or otherwise alter any unrecognized annotation.

## File Naming

Generate filename from the feature: extract key terms, convert to kebab-case, keep concise (2–5 words).

**Examples:**
- "Add user authentication with JWT" → `user-authentication.md`
- "Refactor API error handling" → `api-error-handling.md`

**Path:** `.specs/plans/<filename>.md`

## Quality Checklist

Before finalizing:
- [ ] **REQUIRED:** All steps have numbered headings (`### Step N: Title`) followed by `<!-- specbuddy:step -->` on the very next line — missing this comment is a hard blocker; the step will not execute.
- [ ] All steps have clear success criteria (3–5 each).
- [ ] Dependencies form a valid DAG (no cycles).
- [ ] File references use correct paths.
- [ ] Commands are appropriate for the project.
- [ ] Prerequisites clearly stated.
- [ ] Risks and mitigations identified.
- [ ] **Minimal code examples** (references preferred).
- [ ] Relevant skills mentioned in step descriptions where applicable.

## Error Handling

### Ambiguous Description

Ask clarifying questions: which component? What defines success? What is the current baseline?

### Large Scope (>15 steps)

The plan exceeds the upper bound of the "Very large" category in [Step Granularity](#7-step-granularity). Suggest breaking the work into sub-features and producing multiple related plans rather than one oversized plan.

### Missing Dependencies

Include dependency installation and prerequisite steps in the plan.

## Tools Available

- **Read** — examine files and specifications.
- **Write** — create the plan file.
- **Glob** — discover project structure.
- **Grep** — search for patterns and existing code.
- **Bash** — execute commands for validation (limited use).

## Output

Create the plan at `.specs/plans/<filename>.md` and report:
- File path.
- Number of steps.
- A summary of key milestones.
- A pointer that the user can now proceed to executing the first step (the `spec-execute` skill handles step execution).

Follow the annotation lifecycle described in [Annotation Behavior — Rule 3](#rule-3----specbuddycreate-plan-lifecycle) to handle the `<!-- specbuddy:create-plan -->` annotation.

---

**Philosophy:** plans are executable roadmaps with maximum clarity and minimum code. Reference existing code extensively. Trust the executing agent to figure out implementation details. Good plans are specific, measurable, and incremental.
