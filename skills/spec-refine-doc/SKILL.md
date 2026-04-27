---
name: refine-doc
description: Refine a markdown document (specification, plan, or any other markdown file) based on user feedback. Can target a specific named step or the entire document. Updates the document in place and never touches source code.
triggers:
  - "refine this spec based on my feedback"
  - "update step `Setup` in this plan"
  - "edit the document to address these comments"
  - "revise this specification with my feedback"
  - "rewrite step 2 of the plan based on my notes"
  - "apply this feedback to the markdown document only"
---

# Refine Document

Edit a markdown document (specification, plan, or any other markdown file) based on user feedback. The feedback can target one specific step in the document or apply to the document as a whole. You modify only the document — you do **not** touch source code.

## Input Elicitation

Gather these inputs:
- **Document file path** *(required)* — the markdown file to edit.
- **Step name** *(optional)* — a specific step heading to target, e.g. `Step 2: Hash Password`. If omitted, you operate in **document mode** and treat the feedback as applying to the whole file.
- **User diff path** *(optional, only meaningful in step mode)* — a path to a diff file capturing manual edits the user made to generated code after a previous run. Used as evidence of what the user was dissatisfied with — never re-applied mechanically.
- **Inline comments** *(optional)* — lines of the form `<filePath>:<lineNumber>: <comment>`.
- **Free-form feedback** *(optional)* — additional prose feedback.

If the document path is missing, ask the user for it.

**Mode:** if a step name is provided → **step mode**; otherwise → **document mode**.

## Procedure

### 1. Read the Document

Read the document file. If not found, report the error and stop.

### 2. Read the Diff (step mode only)

In document mode, skip this. In step mode, if a diff path was provided and is non-empty, read it. If the file cannot be read, continue with `(no diff provided)`.

### 3. Refine the Document

You are now refining the document based on the user's feedback. Apply the following workflow yourself; there is no separate sub-agent.

**Inputs you have:**
- The current document contents.
- (Step mode only) the user's diff, if any.
- The user's inline comments and free-form feedback.

**Task:**

1. Read the document carefully.
2. Build an understanding of what the user wants:
   - In step mode, combine the diff (evidence of what went wrong in the implementation) with the inline comments and free-form feedback.
   - In document mode, focus on what the user wants changed about the document's structure, steps, or completeness.
3. Edit the document file in place to apply the requested changes:
   - Rewrite the targeted step (step mode) or the affected sections (document mode).
   - Add new steps or sections if requested.
   - Remove steps or sections if requested.
   - Reorder or split steps if requested.
   - Preserve overall document structure and markdown formatting.
4. Preserve all existing SpecBuddy annotations exactly as they are. In particular, every `<!-- specbuddy:step -->` comment that already exists must stay attached to its step heading on the line immediately after the heading. Do not remove, move, or modify these annotations. Do not touch unknown HTML-comment annotations either.
5. Report a brief summary of the changes you made (which steps or sections were added, modified, or removed).

**Rules:**
- Do NOT touch any source code files. Only modify the document file itself.
- If the feedback is ambiguous, apply the most reasonable interpretation and explicitly note your assumption in your summary.

### 4. Report

After editing, present a concise summary of the changes. If you ended up making no changes (for example because the feedback was unclear), say so explicitly so the user can clarify.
