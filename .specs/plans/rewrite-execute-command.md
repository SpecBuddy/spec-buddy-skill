# Rewrite Execute Command with SubagentStop Hook

**Status:** Draft
**Created:** 2026-03-11
**Last Updated:** 2026-03-11

## Overview

Two related changes to the `/spec-buddy:execute` command:

1. **Launch behavior**: The execute command should immediately launch the step-executor subagent, passing it all context
   that is already available. The subagent then collects any missing context on its own by following the plan step. The
   current approach of pre-collecting all context before launching the subagent is replaced by this eager launch pattern.

2. **Post-execution reminder**: After the step-executor subagent finishes, a `SubagentStop` hook fires and injects a
   reminder into Claude's context: "review the subsequent steps in the plan and update them based on what was discovered
   during execution."

## Goals

- The execute command launches the step-executor subagent immediately, passing available context upfront
- The subagent collects any missing context on its own by following the plan step
- A `SubagentStop` agent-based hook fires when `step-executor` finishes
- The hook injects a reminder to review and update next steps with relevant context discovered during execution

## Non-Goals

- Automatic step updates without user review
- Changing the step-executor agent itself
- Changing how the execute command parses arguments or validates step results

## Background

The execute command currently pre-collects all context referenced in a plan step before launching the step-executor
subagent. This approach is fragile: referenced files may not exist yet, and the subagent is capable of collecting
context on its own. The better approach is to launch the subagent immediately with whatever context is already available,
letting the subagent gather any missing context as part of its execution.

Additionally, after a step executes, the agent often discovers new context (e.g., existing file structures, API shapes,
dependency versions, design patterns) that is relevant for future steps. Currently this context is lost — the user has
to manually remember to update the plan. A `SubagentStop` hook can inject a reminder automatically.

## Technical Design

### Hook Placement

Plugin hooks live in `hooks/hooks.json` at the project root (not under `.claude-plugin/`). The hook is active whenever
the plugin is enabled.

```
hooks/
  hooks.json      ← new file
```

### Hook Configuration

```json
{
    "SubagentStop": [
        {
            "matcher": "step-executor",
            "hooks": [
                {
                    "type": "agent",
                    "prompt": "The step-executor subagent just finished executing a plan step. Review the subagent's output and identify any context discovered during execution that is relevant for subsequent steps (e.g., file structures, API shapes, naming conventions, existing patterns, dependency versions, unexpected findings). Then inject a reminder: list the relevant context items and ask Claude to update the next steps in the plan to reference them. If no useful context was discovered, respond with {\"ok\": true} silently.",
                    "timeout": 30
                }
            ]
        }
    ]
}
```

### How It Works

The step identifier is flexible — any of these forms are accepted:

- Number only: `1`
- Name only: `setup`
- Number + name: `1-setup` or `step-1-setup`

1. User runs `/spec-buddy:execute plan.md 1` (or `plan.md setup`, or `plan.md 1-setup`)
2. Execute command parses args, reads the plan step, and immediately launches `step-executor` subagent via Task tool —
   passing any context that is already available (e.g., `@file` references that resolve); unavailable context is omitted
3. `step-executor` collects any missing context on its own, executes the step, and reports results
4. `SubagentStop` hook fires with matcher `step-executor`
5. Hook's agent reviews the subagent output, identifies discovered context
6. If relevant context found: hook injects reminder into Claude's context about updating next steps
7. Claude (in the main session) sees the reminder and surfaces it to the user

### Fallback if SubagentStop Injection Is Unsupported

If `SubagentStop` doesn't support stdout context injection (needs verification), implement the reminder inside the
execute command itself at step 7 (Display Results):

After showing the agent output, Claude adds:

```
---
**Reminder:** Review the next steps in the plan. Based on what was discovered above, consider updating them to reference:
- [list of any relevant files/patterns/context mentioned in agent output]

Run `/spec-buddy:execute <plan-file> <N+1>` when ready to continue.
```

This fallback is simpler and doesn't require hooks infrastructure.

## Implementation Steps

### Step 1: Update execute command to launch subagent immediately

Change `commands/execute.md` so the execute command launches the step-executor subagent immediately with whatever
context is already available, instead of pre-collecting all context first.

**Context:**

- @file:commands/execute.md
- @file:agents/step-executor.md

**Actions:**

- Read the current execute command to understand its context-collection phase
- Modify the launch logic: pass `@file` references and other context only if they are resolvable at launch time
- Remove any blocking pre-collection that waits for all context to be available before launching
- The subagent receives available context upfront; missing context is for the subagent to gather on its own

**Success Criteria:**

- [ ] Execute command launches the subagent without a pre-collection phase
- [ ] Available context (existing files, resolved references) is passed to the subagent at launch
- [ ] Unresolvable references are omitted rather than causing the launch to wait or fail

### Step 2: Create plugin hooks configuration

Create `hooks/hooks.json` at the project root with the `SubagentStop` agent hook for `step-executor`.

**Context:**

- @file:.claude-plugin/plugin.json
- @file:commands/execute.md

**Actions:**

- Create `hooks/` directory at the project root
- Create `hooks/hooks.json` with the hook configuration shown in Technical Design

**Success Criteria:**

- [ ] `hooks/hooks.json` exists and is valid JSON
- [ ] Hook targets `SubagentStop` event with `step-executor` matcher
- [ ] Hook uses `type: "agent"` with a clear prompt about reviewing context

### Step 3: Test and verify hook behavior

Test the hook by running the execute command and checking if the hook fires correctly.

**Context:**

- @file:hooks/hooks.json
- @file:commands/execute.md

**Actions:**

- Restart Claude Code with the plugin: `claude --plugin-dir /Users/alexander/workspace/spec-buddy-skill`
- Run a test execute command against an existing plan
- Check if the SubagentStop hook fires after step-executor completes
- Check if context injection works (reminder appears in Claude's response)

**Success Criteria:**

- [ ] Hook fires after step-executor finishes
- [ ] If context was discovered: reminder is injected into Claude's context
- [ ] If no useful context: hook exits silently (`ok: true`)
- [ ] No errors in hook execution

### Step 4: Fallback — add reminder to execute command output (if hooks don't support injection)

If `SubagentStop` hooks don't inject context into the main session, add the reminder directly to the execute command's
step 7 (Display Results).

**Context:**

- @file:commands/execute.md#L140-L152

**Actions:**

- Edit `commands/execute.md` step 7 to add a "Reminder" section after showing agent output
- The reminder should scan the agent output for discovered context (files read, patterns found, unexpected findings)
- List them as a reminder to update next steps

**Success Criteria:**

- [ ] Execute command output includes a reminder section after agent results
- [ ] Reminder lists relevant context from agent output
- [ ] Reminder suggests running next step command

## Open Questions

1. Does `SubagentStop` support stdout context injection like `UserPromptSubmit`/`SessionStart`? The docs don't
   explicitly state this for SubagentStop. **Need to test.**
2. ~~What is the correct path for plugin hooks?~~ **Resolved:** Plugin hooks live in `hooks/hooks.json` at the project
   root, not under `.claude-plugin/`.
3. Should the hook always fire, or only when it finds meaningful context? (Current design: silent if nothing useful.)

## References

- Current execute command: `commands/execute.md`
- Step executor agent: `agents/step-executor.md`
- Hooks guide: https://code.claude.com/docs/en/hooks-guide#agent-based-hooks
- Plugin config: `.claude-plugin/plugin.json`
