# Spec Editor Skill

**Status:** Draft
**Created:** 2026-03-11
**Last Updated:** 2026-03-11

## Overview

A command that finalizes a specification document after the user has manually edited it. The user edits the spec directly — some changes are direct text modifications (already reflected in the document), and some are inline notes or requests left for the agent to act on. The command receives the current (already-edited) spec and a diff showing what changed, interprets the user's intent from context, and writes back a clean, polished spec — all within the current Claude session.

## Goals

- Interpret the user's edits and inline notes from the diff and the current document content
- Generate or improve spec content where the user left instructions or placeholders
- Preserve all direct user text edits exactly as written
- Produce a clean, coherent spec without leftover notes or draft markers

## Non-Goals

- Applying a diff to a spec file (the user has already done this)
- Rewriting or improving sections that the user did not touch
- Validating the quality or correctness of the final spec
- Generating the diff itself (that is the user's or tooling's responsibility)

---

## Specification

### Background

Specification documents evolve through iterative review. Users edit specs directly — some edits are straightforward text changes (adding, removing, or rewriting content), while others are inline notes or requests left for the AI to fulfill. After the user finishes editing, the document may contain a mix of finalized content and pending instructions.

The spec editor command bridges this gap. It reads the diff to understand what the user changed and why, reads the current document to see its state, identifies any pending instructions or rough notes, generates appropriate spec content, and writes back a clean document — directly editing the input spec file in place.

**Why resulting document + diff (not original + diff)?**
Since direct text edits are already in the document, the agent only needs the current state as its working copy. The diff is supplementary context — it helps the agent understand *what changed* and *why*, which is critical for interpreting vague instructions like "make this more concise" or "add more detail here". Passing the original + diff would require the agent to reconstruct state unnecessarily.

**Why not embed the full document in the diff?**
A standard unified diff includes only a few lines of context around each change. One alternative would be to expand that context to include the entire document, giving the agent the full picture from the diff alone. In practice this is not worth the cost: for any non-trivial spec, the resulting diff would be as large as the full document for every edit, making it expensive to store and transmit. The current two-input design (current document + compact diff) keeps the diff small while still giving the agent everything it needs.

---

### Inputs

| Input | Type | Description |
|-------|------|-------------|
| `spec_path` | File path | Path to the already-edited specification document (`.md` file) |
| `diff_path` | File path | Path to a unified diff of the spec (showing what the user changed), used as context for interpreting intent |

#### How the Agent Identifies User Intent

No special annotation format is required. The agent infers intent from two sources:

1. **The diff itself** — added lines that look like instructions, questions, or rough notes rather than polished spec prose signal that the user wants the agent to act, not just preserve.
2. **The document content** — inline markers that are conventionally used to flag pending work: `<!-- TODO: ... -->`, `<!-- FIXME: ... -->`, `> [!NOTE]`, or simply unfinished-looking sentences in an otherwise polished document.

The agent is expected to use judgment — the same way a human editor would — to distinguish between content the user intends to keep as-is and content that is a placeholder or instruction.

---

### Future Direction: Single-Document Annotation Format

> This section captures a design idea for a later phase, not a current requirement.

A natural evolution would be a format where a single document contains both the final content and the user's edit annotations, visible in raw markdown but invisible (or clearly demarcated) when rendered.

**Possible approach — inline HTML comment annotations:**

```markdown
## Error Handling

<!-- EDIT: rewrote this section to be more specific -->
The service returns HTTP 408 on timeout after 30 seconds, and HTTP 503 if the upstream is unavailable.

<!-- TODO: add a table of all error codes and their meanings -->
```

- `<!-- EDIT: ... -->` provides context about what changed (helps the agent understand intent without needing a **separate diff**)
- `<!-- TODO: ... -->` requests new content to be inserted at that location

This approach has appealing properties:
- A single file contains both the result and the review annotations
- Rendered markdown looks clean (HTML comments are hidden)
- No separate diff file needed — the annotations encode the author's intent directly
- The agent's job becomes simpler: scan for annotation markers, act on them, remove them

This could replace the current two-file input (spec + diff) in a future version of this skill.

---

### Functional Requirements

**FR-1: Read inputs**
- The command MUST read the full content of the spec file at `spec_path`.
- The command MUST read the full content of the diff file at `diff_path`.

**FR-2: Identify pending instructions**
- The command MUST scan the diff for added lines that appear to be instructions, questions, or rough notes rather than polished spec prose.
- The command MUST also scan the current document for conventional pending-work markers (`<!-- TODO: -->`, `<!-- FIXME: -->`, unfinished placeholders).
- Each identified item must be extracted with its location (surrounding section heading and adjacent lines).

**FR-3: Interpret intent using context**
- For each pending instruction, the command MUST use the surrounding document content and the diff hunk to resolve the intent.
- Relative references ("this", "here", "the section above") must be resolved using surrounding context.
- The command MUST determine whether an instruction targets a single location, a section, or multiple sections across the document — and act accordingly.

**FR-4: Generate content**
- The command MUST generate spec content that satisfies each identified instruction.
- Generated content must match the existing spec's writing style, heading level, terminology, and language (Russian or English).
- Generated content replaces the instruction/placeholder; surrounding finalized content is preserved.
- When an instruction semantically affects multiple sections, the command MUST apply consistent changes across all affected sections.

**FR-5: Write clean spec**
- The command MUST write the updated spec back to `spec_path`, editing the file in place.
- No instruction markers, TODO comments, or rough-draft notes must remain in the output.
- Sections the command did not act on must be written back byte-for-byte identical to the input.

**FR-6: Summary report**
- After writing the file, the command MUST output a brief summary:
  - Number of instructions identified and fulfilled
  - Any instructions that could not be resolved with confidence (with reason)

---

### Non-Functional Requirements

**NFR-1: Precision** — Only content targeted by pending instructions is modified. An instruction may target a single location, a section, or multiple sections across the document — all targeted content is updated accordingly. Content not referenced by any instruction is preserved exactly.

**NFR-2: Language consistency** — Generated content matches the language of the surrounding spec text.

**NFR-3: No diff application** — The command must NOT attempt to re-apply the diff to the spec. The spec is already in its final edited state; the diff is read-only context.

**NFR-4: Minimal footprint** — The command only modifies the spec file; no additional files are created.

---

### Technical Design

#### Implementation Type

A **command** (`commands/spec-editor.md`) invoked directly in the current Claude session via `/spec-buddy:edit`. It runs entirely in-session — no sub-agent is spawned. The command receives `spec_path` and `diff_path` as `$ARGUMENTS` and edits `spec_path` in place.

Running in-session means the command has full access to all Claude tools without restriction, and the user can see and interact with each step as it executes.

#### Tools Used

- `Read` — read the spec and diff files
- `Edit` — write updated sections back to the spec file in place
- `Grep` — locate instruction markers and surrounding context within the spec

#### Processing Algorithm

```
1. Read spec_path → current_spec
2. Read diff_path → diff_context
3. Identify pending instructions:
   a. Scan diff_context for added lines that look like instructions/notes
   b. Scan current_spec for TODO/FIXME markers and unfinished placeholders
   → instructions = list of (location, instruction_text, scope)
4. For each instruction:
   a. Extract surrounding context from current_spec (section heading, adjacent paragraphs)
   b. Find the corresponding hunk(s) in diff_context for additional context
   c. Interpret the instruction using both sources, including all sections it semantically affects
   d. Generate replacement content
   e. Edit spec_path in place: replace the instruction (and any targeted surrounding content) with generated content
      — if the instruction affects multiple sections, apply edits to each affected section
5. Output summary report
```

#### Scope Resolution

The command infers the scope of each instruction from its placement and wording:

| Placement / Wording | Inferred Scope |
|---------------------|----------------|
| Standalone note between paragraphs | Insert new content at that location |
| Note immediately after a heading | Rewrite or expand the entire section |
| Note inline within a paragraph | Rewrite that paragraph |
| Note referencing "the above" / "this section" | Rewrite the preceding block |
| Note that semantically applies to multiple sections | Update all affected sections consistently |

When scope is ambiguous, the command defaults to inserting new content at the instruction's location without removing surrounding text.

---

### Data Models

**PendingInstruction**
```
location: string       # section heading + adjacent lines for context
instruction: string    # the instruction text
scope: enum            # insert | rewrite_paragraph | rewrite_section | rewrite_multiple_sections
affected_sections: list of string   # populated when scope = rewrite_multiple_sections
```

**EditSummary**
```
instructions_found: int
instructions_fulfilled: int
unresolved: list of { location, instruction, reason }
```

---

### Security Considerations

- The command only reads and writes local files specified by the caller.
- No external network access is required or permitted.
- File paths must be validated to be within the workspace to prevent path traversal.

---

### Testing Strategy

| Scenario | Input | Expected Output |
|----------|-------|-----------------|
| Instruction in diff | Spec + diff with an added note like "expand this section" | Section expanded, note not present in output |
| TODO marker in document | Spec with `<!-- TODO: add error table -->` | Table generated, marker removed |
| Direct edit only | Spec + diff with only polished text changes, no notes | Spec written back unchanged except direct edits |
| Vague relative reference | Note saying "make this more concise" + diff providing context | Correct paragraph condensed |
| Unresolvable instruction | Note with no surrounding context | Skipped, reported in summary |
| Multiple instructions | Spec with several notes across sections | All fulfilled independently, clean output |
| Cross-section instruction | Note that semantically affects several sections (e.g. "rename this concept throughout") | All affected sections updated consistently |

---

## Open Questions

- [ ] Should the diff input be mandatory or optional? (Command works without it but with less context for relative instructions.)
- [ ] How should the command handle an instruction it partially fulfills — report as fulfilled or unresolved?
- [ ] Should the summary report be appended to the spec file temporarily, or printed to stdout only?
- [ ] When should the single-document annotation format (see Future Direction) replace the current two-file approach?

---

## References

- `.specs/concept.md` — SpecBuddy concept and spec format
- `commands/` — Existing command configurations for reference
