---
name: refine-doc-and-generation
description: Two-phase refinement that first updates a markdown document (spec or plan) for one named step based on user feedback, and then re-executes that updated step to regenerate the implementation code. Use when both the document and the code need to be brought back into agreement with the user's intent.
triggers:
  - "refine the plan and re-run the step"
  - "update step `Hash Password` and regenerate the code"
  - "fix both the document and the implementation for this step"
  - "the spec is wrong and so is the code — refine and re-execute"
  - "edit step 2 in the plan and run it again"
  - "apply this feedback to both the document and the generation"
---

# Refine Document and Generation

Two-phase refinement for a single step:
1. **Phase 1 — Refine the document.** Update the targeted step in the markdown document based on the user's feedback.
2. **Phase 2 — Re-execute the step.** Re-run the now-updated step to regenerate the implementation code.

You perform both phases yourself — there is no separate sub-agent to dispatch to.

## Input Elicitation

Gather these inputs:
- **Document file path** *(required)* — the plan or specification file containing the step.
- **Step name** *(required)* — the exact name of the step to refine and re-execute, e.g. `Step 2: Hash Password`.
- **User diff path** *(optional)* — a path to a diff file capturing manual edits the user applied to the generated code after the previous run. Treat this as evidence of what the user was dissatisfied with — do not re-apply it mechanically.
- **Inline comments** *(optional)* — lines of the form `<filePath>:<lineNumber>: <comment>`.
- **Free-form feedback** *(optional)* — additional prose feedback.

If the document path or step name is missing, ask the user for them. If the document is not found, report the error and stop.

## Procedure

### 1. Read the Document

Read the document file. If not found, report the error and stop.

### 2. Read the Diff (if provided)

If a diff path was provided and is non-empty, read it. If the file cannot be read, continue with `(no diff provided)`.

---

## Phase 1 — Refine the Document

You are refining the document based on user feedback about a specific step.

**You have:**
- The current document contents.
- (If provided) the user's diff — evidence of what went wrong in the previous implementation. Do NOT re-apply it mechanically.
- The user's inline comments and free-form feedback.

**Task:**

1. Read the document carefully.
2. Read the diff, inline comments, and free-form feedback to understand what went wrong with the previous implementation, and what change in the document would prevent it from happening again.
3. Edit the document file in place to apply the requested changes — typically by rewriting the targeted step, adjusting its actions or success criteria, or splitting/merging it if needed.
4. Preserve all existing SpecBuddy annotations exactly as they are. In particular, every `<!-- specbuddy:step -->` comment must remain on the line immediately after its `### Step N:` heading. Do not remove, move, or modify these annotations. Leave any unrecognized HTML-comment annotations untouched as well.
5. Report a brief summary of the document changes (Phase 1 summary).

**Rules for Phase 1:**
- Do NOT touch any source code files in this phase.
- Only modify the document.
- If the feedback is ambiguous, apply the most reasonable interpretation and note your assumption.

Complete Phase 1 fully before starting Phase 2.

---

## Phase 2 — Re-execute the Updated Step

### 3. Re-read the Document

After Phase 1's edits, re-read the document to obtain the *updated* content of the targeted step.

### 4. Find the Requested Step in the Updated Document

Scan the updated document for headings matching the step name (case-insensitive). Extract the full step section. If not found (for example because Phase 1 renamed the step), list available steps, report the error, and stop.

### 5. Extract Specification Context

Check the updated document's `## References` section for a specification file path. If found, you will read that spec for overall context.

### 6. Execute the Updated Step

🎯 CRITICAL: execute ONLY this one updated step. Do NOT execute other steps.

**You have:**
- The updated step section.
- (If provided) the user's diff — evidence of what was wrong previously. Do NOT re-apply it mechanically.
- The user's inline comments and free-form feedback.
- The specification file (if any) for overall context.

**Workflow:**

1. Read any `@file:` / specification references for context.
2. Use the diff, inline comments, and feedback to understand what was wrong with the previous output.
3. Read any files referenced in the step's "Context" section, plus the files implicated by the feedback.
4. Perform the actions listed in the (now updated) step, correcting the issues described.
5. Validate ALL success criteria for the step.
6. Report your results — list which files were created or modified (Phase 2 summary).

### 7. Final Report

Present the two phases distinctly:
- **Phase 1 summary** — what changed in the document.
- **Phase 2 summary** — what changed in the implementation code, and the status of each success criterion.

If Phase 2 fails (for example, the agent could not satisfy a success criterion), note that Phase 1's document changes are already saved and that the user may retry only the code re-execution via the `spec-refine-generation` skill without re-editing the document.

After reporting, identify (but do not execute) the next step in the document, so the user can decide whether to proceed.
