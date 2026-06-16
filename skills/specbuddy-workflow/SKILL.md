---
name: specbuddy-workflow
description: Mandatory workflow instructions for all SpecBuddy operations. Loaded automatically on every task.
---

# SpecBuddy Workflow — Required Agent Behaviour

These instructions apply to every SpecBuddy operation. Follow them exactly.

---

## Mandatory Notification Protocol

You communicate session state to the IDE by calling `specbuddy_notify.py`. This script lives in the same directory as this skill (`specbuddy-workflow/specbuddy_notify.py`). Resolve its absolute path from the skill's location before calling it. Use the **absolute path** of the spec file for every call.

**You must call exactly one of `session_end` or `session_cancel` to close every session. Missing the closing call leaves the IDE stuck in Running state.**

---

## Rule 1 — session_start before any file write

Call `session_start` **before you modify, create, or delete any file**. This allows the IDE to take a pre-op snapshot and enter Running state.

For `EXPLODE_FIX_PLAN` operations:
```
python3 <skill-dir>/specbuddy_notify.py session_start <specPath> \
  --mode EXPLODE_FIX_PLAN \
  --step-name "explode"   # use "plan" when generating a plan
```

For `RUN_STEP` operations:
```
python3 <skill-dir>/specbuddy_notify.py session_start <specPath> \
  --mode RUN_STEP \
  --step-name "<exact step heading text WITH ALL # HEADING CHARACTERS>"
```

The `session_start` call prints a JSON response to stdout. **You must parse it before doing any work:**

```json
{"worktree_path": "/absolute/path/to/worktree"}
```

- If `worktree_path` is present in the response, **all file reads and writes for this step MUST be performed inside that directory**. Treat it as the project root for the duration of the step. Never modify files in the original project directory while a worktree path is active.
- If the response is `{}` (no `worktree_path`), work in the original project directory as usual.

---

## Rule 2 — session_end after all work is complete

Call `session_end` after **all** file writes for the current operation are finished. This triggers the IDE's Review phase and opens the diff panel.

```
python3 <skill-dir>/specbuddy_notify.py session_end <specPath>
```

---

## Rule 3 — session_cancel on failure or abort

If you cannot complete the operation for any reason, call `session_cancel`. The IDE will roll back to the pre-op snapshot and clear the session.

```
python3 <skill-dir>/specbuddy_notify.py session_cancel <specPath>
```

Do not call `session_end` on failure. Call exactly one of `session_end` or `session_cancel`, never both.

---

## Per-Command Required Sequence

### /spec-buddy:new — Explode specification

1. `session_start … --mode EXPLODE_FIX_PLAN --step-name "explode"`
2. Expand the draft spec (fill all sections; replace `<!-- specbuddy:explode-specification -->` anchor; append `<!-- specbuddy:create-plan -->` at end).
3. `session_end <specPath>`

### /spec-buddy:plan — Generate step plan

1. `session_start … --mode EXPLODE_FIX_PLAN --step-name "plan"`
2. Read the spec; write numbered steps with `<!-- specbuddy:step -->` anchors.
3. `session_end <specPath>`

### /spec-buddy:execute — Execute one step

1. `session_start … --mode RUN_STEP --step-name "<exact heading text>"`
2. Implement all changes for **this step only**. Do not proceed to other steps.
3. `session_end <specPath>`

### /spec-buddy:refine-doc or /spec-buddy:refine-doc-and-generation

1. `session_start … --mode EXPLODE_FIX_PLAN --step-name "refine"`
2. Apply the user's feedback to the document (and re-execute the affected step if instructed).
3. `session_end <specPath>`

### /spec-buddy:refine-generation

1. `session_start … --mode RUN_STEP --step-name "<step being refined>"`
2. Re-implement the step using the user's corrective feedback.
3. `session_end <specPath>`

---

## Invariants

- Never call `session_start` twice without an intervening `session_end` or `session_cancel`.
- `--step-name` for `RUN_STEP` must be the exact heading text from the spec.
- `--step-name` for `EXPLODE_FIX_PLAN` must be one of: `"explode"`, `"plan"`, `"refine"`.
- All paths passed to `specbuddy_notify.py` must be absolute.
