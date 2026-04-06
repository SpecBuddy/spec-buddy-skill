# Implementation Plan: /spec-buddy:plan Command

**Status:** Draft
**Created:** 2026-02-12
**Estimated Effort:** 3-4 hours
**Dependencies:** Existing plugin structure

## Overview

Create `/spec-buddy:plan` command that generates implementation plans. Since this is a Claude Code plugin, implementation means writing clear instructions in markdown that Claude will follow.

## Goals

- Create `commands/plan.md` with instructions for plan generation
- Support three input modes: description, @spec:file, @file:file
- Generate plans using SpecBuddy format (@step markers)
- Test and document the command

## Scope

**In Scope:**
- Command file creation
- Instruction writing for Claude
- Testing with examples
- Documentation

**Out of Scope:**
- Actual code implementation (Claude handles execution)
- Automatic plan execution
- Advanced validation logic

## Prerequisites

- [x] Specification complete (.specs/implementation-plan-command.md)
- [x] Understanding of SpecBuddy format
- [x] Existing command examples (commands/new.md)

## Implementation Steps

@step:start study-existing-command
### Step 1: Study Existing Command

Understand how commands/new.md works.

**Context:**
- @file:commands/new.md
- @file:.claude-plugin/plugin.json

**Actions:**
- Read commands/new.md to understand structure
- Note how $ARGUMENTS is used
- See how Claude is instructed to generate content
- Understand frontmatter format

**Success Criteria:**
- [ ] Understand command structure
- [ ] Know how to use $ARGUMENTS
- [ ] Understand instruction pattern
- [ ] Ready to create similar command

**Estimated Time:** 15 minutes
@step:end

@step:start create-plan-command
### Step 2: Create plan.md Command File

Write the command file with instructions for Claude.

**Context:**
- @file:commands/plan.md (to create)
- @spec:.specs/implementation-plan-command.md

**Actions:**
- Create commands/plan.md
- Add frontmatter:
  ```yaml
  ---
  description: Create an implementation plan for a feature or refactoring
  ---
  ```
- Write instructions for Claude covering:
  - How to parse $ARGUMENTS (check for @spec:, @file:, or plain text)
  - How to analyze codebase (use Glob, Grep, Read tools)
  - How to generate plan structure
  - How to create SpecBuddy markers (@step, @file, @range, @cmd)
  - How to sequence steps with dependencies
  - Where to save file (.specs/plans/)
  - What to include in each step

**Success Criteria:**
- [ ] File created with proper frontmatter
- [ ] Instructions cover all three input modes
- [ ] SpecBuddy marker format documented
- [ ] Plan template structure described
- [ ] File naming and saving logic included
- [ ] Success criteria generation explained

**Dependencies:** study-existing-command
**Estimated Time:** 2 hours
@step:end

@step:start test-description-mode
### Step 3: Test Description Mode

Test plan generation from simple descriptions.

**Context:**
- @file:commands/plan.md

**Actions:**
- @cmd:claude --plugin-dir /Users/alexander/workspace/spec-buddy-skill
- Test cases:
  - `/spec-buddy:plan add user authentication`
  - `/spec-buddy:plan implement caching with Redis`
  - `/spec-buddy:plan add logging to services`
- Review generated plans
- Check for:
  - Proper @step markers
  - Accurate @file references
  - Appropriate @cmd commands
  - Clear success criteria
  - Logical step ordering

**Success Criteria:**
- [ ] Plans generated successfully
- [ ] SpecBuddy markers present and correct
- [ ] Steps are actionable
- [ ] File saved in .specs/plans/
- [ ] Plan quality is good

**Dependencies:** create-plan-command
**Estimated Time:** 30 minutes
@step:end

@step:start test-spec-mode
### Step 4: Test Spec-Based Mode

Test plan generation from existing specifications.

**Context:**
- @file:commands/plan.md
- @spec:.specs/spec-creation-command.md

**Actions:**
- @cmd:claude --plugin-dir /Users/alexander/workspace/spec-buddy-skill
- Run: `/spec-buddy:plan @spec:.specs/spec-creation-command.md`
- Verify:
  - Specification requirements extracted
  - Implementation steps cover all FRs
  - References back to spec included
  - Plan structure matches spec scope

**Success Criteria:**
- [ ] Plan generated from spec
- [ ] Requirements mapped to steps
- [ ] @spec: marker used to reference spec
- [ ] All functional requirements covered
- [ ] Plan is comprehensive

**Dependencies:** test-description-mode
**Estimated Time:** 30 minutes
@step:end

@step:start test-file-mode
### Step 5: Test File Refactoring Mode

Test plan generation for refactoring existing files.

**Context:**
- @file:commands/plan.md
- @file:commands/new.md

**Actions:**
- @cmd:claude --plugin-dir /Users/alexander/workspace/spec-buddy-skill
- Run: `/spec-buddy:plan @file:commands/new.md`
- Verify:
  - File analyzed correctly
  - Refactoring opportunities identified
  - @range markers reference specific lines
  - Functionality preservation emphasized

**Success Criteria:**
- [ ] Plan generated for refactoring
- [ ] Current file structure understood
- [ ] @range markers accurate
- [ ] Improvements identified
- [ ] Testing emphasized

**Dependencies:** test-spec-mode
**Estimated Time:** 30 minutes
@step:end

@step:start refine-instructions
### Step 6: Refine Based on Test Results

Improve command instructions based on testing.

**Context:**
- @file:commands/plan.md
- @file:.specs/plans/ (generated test plans)

**Actions:**
- Review test outputs
- Identify gaps or issues:
  - Missing sections?
  - Unclear instructions?
  - Wrong marker format?
  - Poor step ordering?
- Update commands/plan.md instructions
- Add examples and clarifications
- Improve template structure

**Success Criteria:**
- [ ] Common issues addressed
- [ ] Instructions clearer
- [ ] Examples added where helpful
- [ ] Plan quality improved
- [ ] Edge cases handled

**Dependencies:** test-file-mode
**Estimated Time:** 45 minutes
@step:end

@step:start update-documentation
### Step 7: Update Documentation

Document the new command.

**Context:**
- @file:README.md
- @file:CLAUDE.md

**Actions:**
- Add to README.md:
  - Command description
  - Three usage modes with examples
  - Sample generated plan snippet
- Update CLAUDE.md:
  - Add command to components list
  - Document its purpose
  - Note integration with other commands
- Create example in repo:
  - Save one or two good example plans
  - Reference in documentation

**Success Criteria:**
- [ ] README includes command documentation
- [ ] All modes explained with examples
- [ ] CLAUDE.md updated
- [ ] Example plans included
- [ ] Clear and helpful for users

**Dependencies:** refine-instructions
**Estimated Time:** 30 minutes
@step:end

@step:start final-test
### Step 8: Final Integration Test

Test complete workflow end-to-end.

**Context:**
- @file:commands/plan.md
- @file:commands/new.md

**Actions:**
- @cmd:claude --plugin-dir /Users/alexander/workspace/spec-buddy-skill
- Test workflow:
  1. `/spec-buddy:new add feature X` (create spec)
  2. `/spec-buddy:plan @spec:.specs/feature-x.md` (create plan from spec)
  3. Verify plan is actionable
- Test edge cases:
  - Empty input
  - Non-existent file reference
  - Ambiguous description
- Verify no regressions in other commands

**Success Criteria:**
- [ ] Full workflow works
- [ ] Commands integrate smoothly
- [ ] Edge cases handled gracefully
- [ ] No errors or crashes
- [ ] User experience is good
- [ ] Ready for use

**Dependencies:** update-documentation
**Estimated Time:** 30 minutes
@step:end

## Validation Checklist

- [ ] commands/plan.md exists with proper frontmatter
- [ ] Command appears in Claude's command palette
- [ ] All three modes work (description, @spec, @file)
- [ ] Generated plans use SpecBuddy format correctly
- [ ] @step, @file, @range, @cmd markers are accurate
- [ ] Plans are actionable and complete
- [ ] Documentation updated
- [ ] Examples provided
- [ ] No regressions

## Risks and Mitigations

### Risk 1: Instructions Too Vague
**Mitigation:** Test thoroughly, refine based on results, add examples

### Risk 2: Marker Format Incorrect
**Mitigation:** Reference .specs/concept.md in instructions, show examples

### Risk 3: Plans Not Actionable
**Mitigation:** Emphasize concrete steps and measurable criteria in instructions

## Rollback Plan

If issues arise:
- Delete commands/plan.md
- Revert documentation changes
- Document problems for future attempt

## References

- @spec:.specs/implementation-plan-command.md - Full specification
- @spec:.specs/concept.md - SpecBuddy format
- @file:commands/new.md - Example command structure
- @file:CLAUDE.md - Plugin guide