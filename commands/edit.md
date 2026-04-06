---
description: Finalize a spec after manual edits — interpret inline notes and generate clean content
---

# Spec Editor Command

Finalize a specification document after the user has manually edited it. Some edits are direct text changes already reflected in the document; others are inline notes or instructions left for the agent to act on. This command reads both, generates appropriate content, and writes back a clean, polished spec.

## Usage

```
/spec-buddy:edit <spec_path> <diff_path>
```

**Arguments:**
- `<spec_path>`: Path to the already-edited specification document (`.md` file)
- `<diff_path>`: Path to a unified diff of the spec (what the user changed), used as context for interpreting intent

**Example:**
```
/spec-buddy:edit .specs/my-feature.md .snapshots/my-feature/latest.diff
```

## Instructions

When this command is invoked with `$ARGUMENTS`, follow these steps:

### 1. Parse Arguments

Extract `spec_path` and `diff_path` from `$ARGUMENTS`:
- Expected format: `<spec_path> <diff_path>`
- Both arguments are required.

If arguments are missing or malformed:
- Show error: `Usage: /spec-buddy:edit <spec_path> <diff_path>`
- Stop execution.

### 2. Read Inputs

Use the Read tool to load both files:
- Read `spec_path` → `current_spec`
- Read `diff_path` → `diff_context`

If either file is not found, show an error and stop.

### 3. Identify Pending Instructions

Scan both inputs for content that the user wants the agent to act on rather than preserve:

**From the diff** — look at added lines (`+` prefix). Lines that look like instructions, questions, rough notes, or non-spec prose signal intent:
- Natural-language requests: "add more detail here", "make this more concise", "rename X to Y throughout"
- Questions: "should we handle this case?"
- Unfinished markers: `TODO`, `FIXME`, `???`
- Non-English inline notes mixed into an otherwise English spec (or vice versa)

**From the document** — look for conventional pending-work markers anywhere in the current text:
- `<!-- TODO: ... -->`, `<!-- FIXME: ... -->`
- Placeholder text like `[TBD]`, `[describe here]`
- Visually unfinished sentences at the end of otherwise polished sections

For each identified instruction, record:
- **location**: the nearest section heading and surrounding lines
- **instruction text**: verbatim
- **scope**: see Scope Resolution below

### 4. Resolve Scope for Each Instruction

Infer how much of the document each instruction targets:

| Placement / Wording | Scope |
|---------------------|-------|
| Standalone note between paragraphs | `insert` — add new content at that location |
| Note immediately after a heading | `rewrite_section` — rewrite or expand the whole section |
| Note inline within a paragraph | `rewrite_paragraph` — rewrite that paragraph |
| Note referencing "the above" / "this section" | `rewrite_paragraph` — rewrite the preceding block |
| Note that semantically applies across sections (e.g. "rename X to Y throughout", "this applies everywhere") | `rewrite_multiple_sections` — update all affected sections consistently |

When scope is ambiguous, default to `insert` — add content at the instruction's location without removing surrounding text.

### 5. Generate and Apply Content

For each pending instruction, in order:

1. Extract surrounding context: section heading, adjacent paragraphs, and the corresponding diff hunk.
2. Resolve any relative references ("this", "here", "the section above") using that context.
3. Generate replacement spec content that:
   - Satisfies the instruction
   - Matches the document's writing style, heading level, terminology, and language
   - Reads as polished, finalized spec prose — no hedging, no draft markers
4. Use the Edit tool to apply the change:
   - Replace the instruction/placeholder (and any targeted surrounding content) with the generated content.
   - For `rewrite_multiple_sections`: apply consistent edits to every affected section.
   - For `insert`: insert the generated content at the instruction's location and remove only the instruction itself.
5. Direct text edits that are already reflected in the document (polished additions or rewrites with no instruction intent) must be left exactly as written — do not alter them.

### 6. Output Summary Report

After all edits are written, output a brief summary to the user (not to the file):

```
Spec editor complete.

Instructions found: N
Instructions fulfilled: N
Unresolved: N

[If any unresolved:]
- [location]: [instruction] — [reason it could not be fulfilled]
```

If all instructions were fulfilled and nothing was skipped, omit the Unresolved line.

## Scope and Precision

- **Only content targeted by pending instructions is modified.** All other content is written back unchanged.
- The diff is read-only context — never re-apply it to the spec.
- No additional files are created; only `spec_path` is modified.

## Error Handling

**File not found:**
```
Error: File not found: <path>
```

**Missing arguments:**
```
Error: Missing arguments.
Usage: /spec-buddy:edit <spec_path> <diff_path>
Example: /spec-buddy:edit .specs/my-feature.md .snapshots/my-feature/latest.diff
```

**Instruction could not be resolved:**
Include in the summary report with a brief reason (e.g., "no surrounding context", "contradicts existing content").

## Examples

### Inline note in diff
```
User: /spec-buddy:edit .specs/api.md .snapshots/api/latest.diff

Diff contains: +expand the error handling section with specific HTTP codes

→ Agent reads both files
→ Identifies the note as an instruction targeting the Error Handling section
→ Generates a detailed paragraph listing HTTP codes
→ Replaces the note with the generated content
→ Summary: Instructions found: 1, fulfilled: 1
```

### TODO marker in document
```
Diff contains: +<!-- TODO: add a table of all error codes -->

→ Agent finds the TODO marker in the document
→ Generates a markdown table of error codes at that location
→ Removes the TODO marker
→ Summary: Instructions found: 1, fulfilled: 1
```

### Cross-section rename
```
Diff contains: +rename "agent" to "command" throughout this document

→ Agent identifies all sections using the word "agent" in the relevant sense
→ Updates each section consistently
→ Removes the instruction note
→ Summary: Instructions found: 1, fulfilled: 1 (4 sections updated)
```

### Direct edit only (no notes)
```
Diff shows only polished text rewrites, no instruction-like lines

→ Agent finds no pending instructions
→ Spec is written back unchanged
→ Summary: Instructions found: 0
```
