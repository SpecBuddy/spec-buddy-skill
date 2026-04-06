# Implementation Plan: /spec-buddy:execute Command

**Status:** Draft
**Created:** 2026-02-12
**Estimated Effort:** 2-3 hours
**Dependencies:** Existing plugin structure, Task tool

## Overview

Implement `/spec-buddy:execute` command that executes individual steps from implementation plans by launching agents with specification context.

## Goals

- Create functional execute command
- Support step-by-step plan execution
- Pass both spec and step to agent
- Ensure agent executes ONLY one step

## Scope

**In Scope:**
- Command file creation
- Spec reference extraction
- Step extraction
- Agent launching with correct context
- Testing with examples

**Out of Scope:**
- Status tracking (Phase 2)
- Auto-execution of all steps (Phase 2)
- Parallel execution (Phase 2)

## Prerequisites

- [x] Specification complete (.specs/plan-execution-command.md)
- [x] Understanding of Task tool
- [x] Example plans available for testing

## Implementation Steps

@step:start create-command-file
### Step 1: Create Command File

Create `commands/execute.md` with instructions for Claude.

**Context:**
- @file:commands/new.md (reference example)
- @spec:.specs/plan-execution-command.md

**Actions:**
- Create `commands/execute.md`
- Add frontmatter:
  ```yaml
  ---
  description: Execute one step from an implementation plan
  ---
  ```
- Write instructions covering:
  - Argument parsing: `<plan-file> <step-id>`
  - Reading plan file
  - Finding @spec: reference in References section
  - Reading specification file
  - Finding step between @step:start and @step:end
  - Launching agent with Task tool
  - Agent prompt template with spec + step
  - Emphasizing "execute ONE step ONLY"
  - Displaying results

**Success Criteria:**
- [ ] File created at commands/execute.md
- [ ] Frontmatter valid
- [ ] Instructions complete and clear
- [ ] Agent prompt template includes spec and step
- [ ] Explicit "ONE step ONLY" instruction

**Estimated Time:** 1.5 hours
@step:end

@step:start test-with-simple-step
### Step 2: Test with Simple Step

Test command with a simple step execution.

**Context:**
- @file:commands/execute.md
- @file:.specs/plans/implement-plan-command.md

**Actions:**
- @cmd:claude --plugin-dir /Users/alexander/workspace/spec-buddy-skill
- Run: `/spec-buddy:execute .specs/plans/implement-plan-command.md study-existing-command`
- Verify:
  - Command reads plan file
  - Finds @spec reference
  - Reads specification
  - Extracts correct step
  - Launches agent
  - Agent receives both spec and step
  - Agent executes only that step

**Success Criteria:**
- [ ] Command executes without errors
- [ ] Agent receives specification context
- [ ] Agent receives step content
- [ ] Agent understands to execute ONE step only
- [ ] Results displayed clearly
- [ ] Success criteria validated

**Dependencies:** create-command-file
**Estimated Time:** 30 minutes
@step:end

@step:start test-with-code-step
### Step 3: Test with Code Implementation Step

Test with a step that requires code changes.

**Context:**
- @file:commands/execute.md
- @file:.specs/plans/implement-plan-command.md

**Actions:**
- @cmd:claude --plugin-dir /Users/alexander/workspace/spec-buddy-skill
- Run: `/spec-buddy:execute .specs/plans/implement-plan-command.md create-plan-command`
- Verify:
  - Agent receives specification
  - Agent understands the step
  - Agent can create/modify files
  - Agent validates success criteria
  - Agent doesn't proceed to next steps

**Success Criteria:**
- [ ] Agent executes the step
- [ ] Files created/modified as needed
- [ ] Success criteria checked
- [ ] Agent stops after THIS step
- [ ] Clear execution report

**Dependencies:** test-with-simple-step
**Estimated Time:** 30 minutes
@step:end

@step:start test-edge-cases
### Step 4: Test Edge Cases

Test error handling and edge cases.

**Context:**
- @file:commands/execute.md

**Actions:**
- @cmd:claude --plugin-dir /Users/alexander/workspace/spec-buddy-skill
- Test cases:
  1. Invalid plan file: `/spec-buddy:execute nonexistent.md step-1`
  2. Invalid step ID: `/spec-buddy:execute plan.md invalid-step`
  3. No arguments: `/spec-buddy:execute`
  4. Plan without @spec reference
- Verify error messages are helpful

**Success Criteria:**
- [ ] Invalid plan file → clear error
- [ ] Invalid step ID → list available steps
- [ ] No arguments → usage example
- [ ] Missing spec → warning, continues
- [ ] All errors handled gracefully

**Dependencies:** test-with-code-step
**Estimated Time:** 20 minutes
@step:end

@step:start refine-instructions
### Step 5: Refine Based on Testing

Improve command based on test results.

**Context:**
- @file:commands/execute.md

**Actions:**
- Review test results
- Identify issues or unclear instructions
- Update commands/execute.md:
  - Clarify ambiguous parts
  - Add examples
  - Improve error handling instructions
  - Strengthen "ONE step ONLY" messaging

**Success Criteria:**
- [ ] Common issues addressed
- [ ] Instructions clearer
- [ ] Error handling improved
- [ ] Examples added
- [ ] Agent prompt refined

**Dependencies:** test-edge-cases
**Estimated Time:** 20 minutes
@step:end

@step:start update-documentation
### Step 6: Update Documentation

Document the new command.

**Context:**
- @file:README.md
- @file:CLAUDE.md

**Actions:**
- Update README.md:
  - Add command description
  - Show usage example
  - Explain workflow (new → plan → execute)
  - Include example output
- Update CLAUDE.md:
  - Add command to components list
  - Document purpose and integration
- Create usage example in repo

**Success Criteria:**
- [ ] README includes /spec-buddy:execute
- [ ] Usage example clear
- [ ] Workflow documented
- [ ] CLAUDE.md updated
- [ ] Example provided

**Dependencies:** refine-instructions
**Estimated Time:** 20 minutes
@step:end

@step:start final-integration-test
### Step 7: Final End-to-End Test

Test complete workflow from spec to execution.

**Context:**
- @file:commands/new.md
- @file:commands/execute.md

**Actions:**
- @cmd:claude --plugin-dir /Users/alexander/workspace/spec-buddy-skill
- Run full workflow:
  1. `/spec-buddy:new simple feature` → create spec
  2. Review and adjust spec
  3. Create plan manually (or wait for /spec-buddy:plan)
  4. `/spec-buddy:execute plan.md step-1` → execute first step
  5. Review results
  6. `/spec-buddy:execute plan.md step-2` → execute second step
  7. Verify each step executed correctly
- Test that agents only execute assigned step

**Success Criteria:**
- [ ] Full workflow works smoothly
- [ ] Each step executes independently
- [ ] Agents don't skip ahead
- [ ] Results are clear
- [ ] Command integrates with other commands
- [ ] No regressions

**Dependencies:** update-documentation
**Estimated Time:** 30 minutes
@step:end

## Validation Checklist

- [ ] commands/execute.md created with proper frontmatter
- [ ] Command appears in Claude Code
- [ ] Plan file reading works
- [ ] @spec: reference extraction works
- [ ] Step extraction works (between @step:start and @step:end)
- [ ] Agent receives specification context
- [ ] Agent receives step content
- [ ] Agent prompt emphasizes "ONE step ONLY"
- [ ] Error handling works
- [ ] Documentation complete
- [ ] No regressions in existing commands

## Risks and Mitigations

### Risk 1: Agent Executes Multiple Steps
**Mitigation:** Strong emphasis in prompt, test thoroughly, make it very explicit

### Risk 2: Missing Spec Reference
**Mitigation:** Handle gracefully, warn user, continue with reduced context

### Risk 3: Malformed Plans
**Mitigation:** Clear error messages, suggest fixes

## Rollback Plan

If issues arise:
- Delete commands/execute.md
- Revert documentation changes
- Document problems for future attempt

## References

- @spec:.specs/plan-execution-command.md
- @spec:.specs/implementation-plan-command.md
- @spec:.specs/concept.md
- @file:CLAUDE.md