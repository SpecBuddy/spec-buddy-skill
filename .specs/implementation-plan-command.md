# Implementation Plan Creation Command

**Status:** Draft
**Created:** 2026-02-12
**Last Updated:** 2026-02-12

## Overview

This specification describes a new `/spec-buddy:plan` command for the Claude Code plugin that generates executable implementation plans. The command analyzes a codebase or feature description and creates a structured, step-by-step implementation plan in plain markdown format.

## Goals

- Generate actionable, step-by-step implementation plans from high-level descriptions
- Produce plans in plain markdown format that can be executed step-by-step by AI agents
- Automatically identify relevant files, commands, and dependencies
- Break down complex features into manageable implementation steps
- Support both greenfield development and refactoring scenarios
- Enable seamless handoff from planning to execution

## Non-Goals

- Automatic execution of implementation plans (future feature)
- Real-time plan updates during implementation
- Version control management
- Dependency resolution beyond documentation
- Code generation (handled separately during execution)

## Background

### Context

Developers often struggle to break down complex features into concrete implementation steps. The planning phase is critical but time-consuming, requiring analysis of existing code, identification of dependencies, and sequencing of changes. AI-assisted plan generation can accelerate this process while ensuring completeness.

### Motivation

1. **Reduce Planning Overhead**: Automate the breakdown of features into steps
2. **Ensure Completeness**: AI can identify edge cases and dependencies developers might miss
3. **Standardization**: Consistent plan format enables better tooling and automation
4. **Executable Plans**: SpecBuddy format allows future AI agents to execute plans directly
5. **Knowledge Capture**: Plans document the intended approach before implementation begins

### Relationship to Existing Commands

- **`/spec-buddy:new`**: Creates specifications (what to build)
- **`/spec-buddy:plan`**: Creates implementation plans (how to build it)
- **`/spec-buddy:analyze`**: Validates specifications and plans

## Requirements

### Functional Requirements

#### FR1: Command Invocation
- **ID**: FR1
- **Priority**: P0
- **Description**: Support multiple invocation modes
- **Acceptance Criteria**:
  - `/spec-buddy:plan [description]` - Generate plan from description
  - `/spec-buddy:plan spec:path/to/spec.md` - Generate plan from existing spec
  - `/spec-buddy:plan file:path/to/file.ext` - Generate refactoring plan for file
  - Command appears in Claude Code command palette
  - Accepts optional arguments for scope control

#### FR2: Codebase Analysis
- **ID**: FR2
- **Priority**: P0
- **Description**: Analyze existing codebase to inform plan generation
- **Acceptance Criteria**:
  - Identify relevant files that need modification
  - Detect existing patterns and conventions
  - Understand project structure and dependencies
  - Recognize testing frameworks and build tools
  - Identify configuration files and entry points

#### FR3: Dependency Identification
- **ID**: FR3
- **Priority**: P0
- **Description**: Determine dependencies between implementation steps
- **Acceptance Criteria**:
  - Order steps based on dependencies
  - Identify blocking relationships
  - Flag circular dependencies
  - Suggest parallel-executable steps
  - Document prerequisite conditions

#### FR4: Step Generation
- **ID**: FR4
- **Priority**: P0
- **Description**: Generate detailed implementation steps in plain markdown
- **Acceptance Criteria**:
  - Each step has clear description and purpose under a `### Step N:` heading
  - Steps include file references in plain prose (e.g., `See \`path/to/file\``)
  - Commands listed under Actions as `Run: \`command\``
  - Success criteria are specific and measurable
  - Line ranges use `path/to/file#L10-L42` notation

#### FR5: Plan Customization
- **ID**: FR5
- **Priority**: P1
- **Description**: Allow users to customize plan granularity and scope
- **Acceptance Criteria**:
  - Support different detail levels (high-level, detailed, verbose)
  - Allow exclusion of certain aspects (e.g., "skip tests")
  - Enable focus on specific components
  - Support incremental planning (plan one feature at a time)

#### FR6: File Management
- **ID**: FR6
- **Priority**: P0
- **Description**: Save generated plans appropriately
- **Acceptance Criteria**:
  - Generate filename from feature description
  - Default to `.specs/plans/` directory
  - Support custom paths
  - Avoid overwriting without confirmation
  - Create directory structure if needed

#### FR7: Plan Validation
- **ID**: FR7
- **Priority**: P1
- **Description**: Validate generated plans for completeness
- **Acceptance Criteria**:
  - Check all @file references exist
  - Validate @cmd commands are available
  - Verify @range line numbers are valid
  - Ensure all steps have success criteria
  - Warn about potential issues

### Non-Functional Requirements

#### NFR1: Analysis Performance
- **Priority**: P1
- **Description**: Plan generation should be reasonably fast
- **Target**:
  - < 30 seconds for small features (< 5 files affected)
  - < 2 minutes for medium features (5-20 files)
  - < 5 minutes for large features (20+ files)

#### NFR2: Plan Quality
- **Priority**: P0
- **Description**: Generated plans must be actionable and complete
- **Criteria**:
  - All steps can be executed by a developer or AI agent
  - No ambiguous or vague instructions
  - Clear success criteria for each step
  - Realistic step boundaries (not too granular or too broad)

#### NFR3: Reference Accuracy
- **Priority**: P0
- **Description**: File and command references in plans must be correct
- **Criteria**:
  - Referenced file paths are valid and exist
  - Line ranges are accurate
  - Commands are executable in project context

#### NFR4: Plan Maintainability
- **Priority**: P1
- **Description**: Plans should be easy to update and modify
- **Criteria**:
  - Clear markdown structure
  - Steps can be reordered or removed
  - Adding new steps doesn't break format
  - Version control friendly (minimal diffs)

#### NFR5: Code Minimalism
- **Priority**: P0
- **Description**: Plans should minimize code examples and maximize references
- **Criteria**:
  - Prefer plain file references over code snippets (e.g., `See \`src/auth/jwt.ts\``)
  - Only include declarations/signatures when absolutely necessary
  - Never include full implementations
  - Reference existing code patterns instead of showing examples
  - Only include real code if 99% confident agent cannot handle without it
  - Trust executing agent to figure out implementation details

## Technical Design

### Architecture

```
User Input (description / spec:path / file:path)
    ↓
Command Entry Point (commands/plan.md)
    ├─> Validate arguments
    ├─> Parse input mode (description/spec:/file:)
    └─> Verify file existence if needed
    ↓
Launch Plan Generator Agent (via Task tool)
    ↓
Plan Generator Agent (agents/plan-generator.md)
    ├─> Codebase Scanner (Glob, Grep, Read)
    ├─> Dependency Analyzer
    ├─> Pattern Detector
    ├─> Step Sequencer
    └─> Validation Engine
    ↓
File Writer (Write tool)
    ↓
Agent Reports Results
    ↓
Command Displays Summary & Next Steps
```

### Component Architecture

**Command (`commands/plan.md`):**
- Entry point for user invocation
- Validates arguments
- Parses input mode
- Launches plan-generator agent via Task tool
- Displays results and next steps

**Agent (`agents/plan-generator.md`):**
- Specialized in plan generation
- Analyzes codebase structure and conventions
- Generates plain markdown implementation plans
- **Key principle: Minimize code examples, maximize references**
- Uses plain file and line range references
- Ensures proper step sequencing
- Writes plan file to `.specs/plans/`

### Command Implementation

`commands/plan.md` structure:

```yaml
---
description: Create an implementation plan for a feature or refactoring
---
```

Responsibilities:
1. Validate `$ARGUMENTS` presence
2. Parse mode (description/spec:/file:)
3. Verify file existence for spec: and file: modes
4. Launch plan-generator agent with appropriate context
5. Display results summary

### Plan Template Structure

```markdown
# Implementation Plan: [Feature Name]

**Status:** Draft
**Created:** YYYY-MM-DD
**Estimated Effort:** [X hours/days]
**Dependencies:** [List of external dependencies]

## Overview
Brief description of what will be implemented

## Goals
- Primary objectives

## Scope
**In Scope:**
- What this plan covers

**Out of Scope:**
- What's excluded

## Prerequisites
- [ ] Prerequisite 1
- [ ] Prerequisite 2

## Implementation Steps

### Step 1: Environment Preparation
Description of setup needed

**Context:**
- See `package.json`
- See `tsconfig.json`

**Actions:**
- Run: `npm install <dependencies>`
- Run: `npm run setup`

**Success Criteria:**
- [ ] All dependencies installed
- [ ] Build passes
- [ ] Tests run successfully

**Dependencies:** none
**Estimated Time:** 30 minutes

### Step 2: Create Data Models
Description of data structures needed

**Context:**
- See `src/types/index.ts`
- See `src/models/User.ts#L1-L50`

**Actions:**
- Create new model files
- Update type definitions
- Add validation schemas

**Success Criteria:**
- [ ] Types defined and exported
- [ ] Validation logic implemented
- [ ] Tests cover edge cases

**Dependencies:** Step 1
**Estimated Time:** 1 hour

### Step 3: Core Logic Implementation
Main feature implementation

**Context:**
- See `src/services/FeatureService.ts`
- See `src/utils/helpers.ts`

**Actions:**
- Implement service methods
- Add error handling
- Update existing integrations

**Success Criteria:**
- [ ] Core functionality works
- [ ] Error cases handled
- [ ] Integration points updated

**Dependencies:** Step 2
**Estimated Time:** 3 hours

### Step 4: Testing
Comprehensive test coverage

**Context:**
- See `tests/feature.test.ts`
- See `tests/integration.test.ts`

**Actions:**
- Run: `npm run test:watch`
- Write unit tests
- Write integration tests
- Test edge cases

**Success Criteria:**
- [ ] Unit test coverage > 80%
- [ ] All integration tests pass
- [ ] Edge cases covered

**Dependencies:** Step 3
**Estimated Time:** 2 hours

### Step 5: Documentation
Update docs and examples

**Context:**
- See `README.md`
- See `docs/api.md`

**Actions:**
- Update API documentation
- Add usage examples
- Update changelog

**Success Criteria:**
- [ ] API docs complete
- [ ] Examples tested
- [ ] Changelog updated

**Dependencies:** Step 4
**Estimated Time:** 1 hour

## Validation Checklist
- [ ] All files referenced exist
- [ ] All commands are executable
- [ ] Step dependencies are valid
- [ ] Success criteria are measurable
- [ ] Time estimates are realistic

## Risks and Mitigations
- **Risk 1:** [Description]
  - *Mitigation:* [Strategy]

## Rollback Plan
Steps to undo changes if implementation fails

## References
- `related-spec.md`
- Link to design docs
- Link to related issues
```

### Reference Generation Guidelines

The agent must generate references with emphasis on plain file paths over code:

#### File References
- Scan codebase for relevant files
- Identify files that need creation vs modification
- Use backtick paths in prose: `See \`src/services/AuthService.ts\``
- Example: "Follow pattern in `src/services/AuthService.ts`"

#### Line Range References
- Identify specific line ranges for modifications
- Format: `path/to/file#L10-L42`
- Example: "Implement error handling following `src/api/handlers.ts#L12-L34`"

#### Command References
- Detect project's package manager (npm, yarn, pnpm, bun)
- List under Actions as: `Run: \`npm run test:unit\``

### Code Example Guidelines

**CRITICAL PRINCIPLE:** Minimize code in plans. Trust the executing agent.

**Hierarchy of preference:**
1. **Best:** Reference existing code via plain file paths and line ranges
2. **Good:** Describe what to do without code
3. **Acceptable:** Show only declarations/signatures if needed
4. **Last resort:** Include minimal implementation code (99% confidence rule)

**Examples:**

❌ **BAD - Full implementation:**
```markdown
Create authentication service:
```typescript
export class AuthService {
  async login(email: string, password: string) {
    const user = await db.users.findOne({ email });
    ...
  }
}
```
```

✅ **GOOD - References:**
```markdown
Create `src/services/AuthService.ts`:
- Follow the service pattern in `src/services/UserService.ts`
- Implement login(email, password) method
- Use bcrypt for password comparison (see `src/utils/crypto.ts#L15-L25`)
- Use JWT for token generation (see `src/utils/jwt.ts`)
```

### Analysis Modes

#### Mode 1: From Description
```
/spec-buddy:plan Add user authentication with JWT
```
- Parse description
- Infer requirements
- Scan for auth-related patterns
- Generate plan based on best practices

#### Mode 2: From Specification
```
/spec-buddy:plan spec:.specs/user-auth.md
```
- Read specification file
- Extract requirements
- Map requirements to implementation steps
- Reference spec for acceptance criteria

#### Mode 3: From File (Refactoring)
```
/spec-buddy:plan file:src/legacy/UserService.ts
```
- Analyze existing file
- Identify refactoring opportunities
- Generate modernization plan
- Preserve functionality while improving code

### Step Sequencing Algorithm

```javascript
function sequenceSteps(steps, dependencies) {
  // 1. Build dependency graph
  const graph = buildDependencyGraph(steps);

  // 2. Topological sort
  const sorted = topologicalSort(graph);

  // 3. Identify parallel opportunities
  const parallelGroups = identifyParallelSteps(sorted);

  // 4. Add blocking relationships
  annotateBlockingSteps(parallelGroups);

  return sorted;
}
```

## Edge Cases and Error Handling

### EC1: Ambiguous Description
- **Scenario**: `/spec-buddy:plan improve performance`
- **Handling**: Ask clarifying questions:
  - Which component needs optimization?
  - What metrics define success?
  - What's the current baseline?

### EC2: No Existing Code
- **Scenario**: Plan for greenfield project
- **Handling**:
  - Focus on setup and scaffolding steps
  - Include project initialization
  - Add boilerplate creation steps

### EC3: Large Scope
- **Scenario**: Description requires 50+ steps
- **Handling**:
  - Warn about complexity
  - Suggest breaking into sub-features
  - Offer to create multiple related plans
  - Generate high-level plan with sub-plan references

### EC4: Missing Dependencies
- **Scenario**: Required files or tools don't exist
- **Handling**:
  - Include dependency installation in plan
  - Add prerequisite steps
  - Document what needs to be available

### EC5: Conflicting Requirements
- **Scenario**: Steps have circular dependencies
- **Handling**:
  - Detect cycles in dependency graph
  - Suggest restructuring
  - Identify which dependency to break

### EC6: Invalid File References
- **Scenario**: Generated @file path doesn't exist
- **Handling**:
  - Validate during generation
  - Mark as "to be created" vs "to be modified"
  - Include creation steps if needed

### EC7: Outdated Codebase Context
- **Scenario**: Codebase changed since plan creation
- **Handling**:
  - Add validation step at plan start
  - Include checksums or timestamps
  - Warn if referenced files changed

## Security Considerations

### Path Validation
- Validate all @file paths stay within project directory
- Prevent path traversal attacks
- Sanitize user input in file paths

### Command Safety
- Validate @cmd commands don't include dangerous operations
- Warn about destructive commands (rm, drop, delete)
- Require confirmation for risky operations

### Data Exposure
- Don't include sensitive data in plans
- Redact credentials or secrets from examples
- Avoid exposing internal architecture publicly

### Access Control
- Respect file permissions during analysis
- Don't expose unauthorized file contents
- Handle permission errors gracefully

## Implementation Steps

### Step 1: Create Plan Generator Agent

Create specialized agent for plan generation with code minimalism principles.

**Context:**
- See `agents/spec-reviewer.md` (example agent structure)
- See `agents/step-executor.md` (example agent structure)

**Actions:**
- Create `agents/plan-generator.md` with agent definition
- Add frontmatter: role, model (sonnet), description
- Add "Code Minimalism" section with clear guidelines
- Document plan generation workflow
- Specify available tools: Read, Write, Glob, Grep, Bash
- Add examples of good vs bad code inclusion

**Success Criteria:**
- [ ] Agent file created at `agents/plan-generator.md`
- [ ] Code minimalism principles clearly documented
- [ ] Plan generation workflow defined
- [ ] Examples included for reference vs code
- [ ] Tools and capabilities specified

**Dependencies:** none
**Estimated Time:** 2 hours

### Step 2: Create Command Entry Point

Create command that launches the plan generator agent.

**Context:**
- See `commands/new.md` (example command)
- See `agents/plan-generator.md` (agent to launch)

**Actions:**
- Create `commands/plan.md` with frontmatter
- Add argument validation logic
- Add mode parsing (description/spec:/file:)
- Use Task tool to launch plan-generator agent
- Create prompt template for agent
- Add result display logic

**Success Criteria:**
- [ ] Command file created
- [ ] Frontmatter valid
- [ ] Validates arguments
- [ ] Parses all three input modes
- [ ] Launches agent via Task tool
- [ ] Displays results summary

**Dependencies:** Step 1
**Estimated Time:** 1.5 hours

### Step 3: Test Description Mode

Test plan generation from simple descriptions.

**Context:**
- See `commands/plan.md`
- See `agents/plan-generator.md`

**Actions:**
- Run: `claude --plugin-dir /Users/alexander/workspace/spec-buddy-skill`
- Test: `/spec-buddy:plan add user authentication`
- Test: `/spec-buddy:plan implement caching with Redis`
- Verify minimal code in generated plans

**Success Criteria:**
- [ ] Plans generated successfully
- [ ] Minimal or no code examples
- [ ] Extensive use of plain file references
- [ ] Steps are actionable
- [ ] Plans saved in `.specs/plans/`

**Dependencies:** Step 2
**Estimated Time:** 45 minutes

### Step 4: Test Spec-Based Mode

Test plan generation from existing specifications.

**Context:**
- See `commands/plan.md`
- See `.specs/spec-creation-command.md`

**Actions:**
- Run: `claude --plugin-dir /Users/alexander/workspace/spec-buddy-skill`
- Test: `/spec-buddy:plan spec:.specs/spec-creation-command.md`
- Verify specification requirements mapped to steps

**Success Criteria:**
- [ ] Plan generated from spec
- [ ] Requirements mapped to steps
- [ ] Source spec referenced in plan
- [ ] All functional requirements covered
- [ ] References used instead of code

**Dependencies:** Step 3
**Estimated Time:** 30 minutes

### Step 5: Test File Refactoring Mode

Test plan generation for refactoring existing files.

**Context:**
- See `commands/plan.md`
- See `commands/new.md` (file to refactor)

**Actions:**
- Run: `claude --plugin-dir /Users/alexander/workspace/spec-buddy-skill`
- Test: `/spec-buddy:plan file:commands/new.md`
- Verify file analysis and refactoring suggestions

**Success Criteria:**
- [ ] Plan generated for refactoring
- [ ] Current file structure understood
- [ ] Line ranges reference specific sections
- [ ] Improvements identified
- [ ] Existing code referenced, not duplicated

**Dependencies:** Step 4
**Estimated Time:** 30 minutes

### Step 6: Refine Agent Based on Tests

Improve agent instructions based on testing feedback.

**Context:**
- See `agents/plan-generator.md`
- Generated test plans from previous steps

**Actions:**
- Review test outputs for code minimalism
- Identify where agent included too much code
- Strengthen guidelines and examples
- Update workflow instructions

**Success Criteria:**
- [ ] Agent produces minimal code in plans
- [ ] References used extensively
- [ ] Guidelines strengthened
- [ ] Quality of generated plans improved

**Dependencies:** Step 5
**Estimated Time:** 1 hour

### Step 7: Documentation

Document the command, agent, and architecture.

**Context:**
- See `README.md`
- See `CLAUDE.md`

**Actions:**
- Update `CLAUDE.md` with agent architecture
- Add command to README with examples
- Add troubleshooting section

**Success Criteria:**
- [ ] CLAUDE.md explains command→agent flow
- [ ] README includes usage examples
- [ ] Clear for users and developers

**Dependencies:** Step 6
**Estimated Time:** 1 hour

## Testing Strategy

### Unit Tests
- Step sequencing algorithm
- Dependency graph construction
- Marker generation logic
- Path validation

### Integration Tests
- End-to-end command execution
- Codebase analysis with real projects
- Multi-mode invocation (description, @spec, @file)
- Error scenarios

### Manual Tests
- Generate plans for real features
- Execute generated plans manually
- Verify marker accuracy
- Test with different project types

### Test Projects
- TypeScript/React project
- Python/FastAPI project
- Go microservice
- Monorepo structure

### Acceptance Tests

#### AT1: Basic Plan Generation
- **Given**: `/spec-buddy:plan add user profile page`
- **Then**: Generate plan with setup, implementation, testing steps
- **Verify**: All markers valid, steps ordered, criteria present

#### AT2: Spec-Based Planning
- **Given**: `/spec-buddy:plan spec:.specs/user-auth.md`
- **Then**: Generate plan matching spec requirements
- **Verify**: All spec requirements mapped to steps

#### AT3: Refactoring Plan
- **Given**: `/spec-buddy:plan file:src/legacy/Controller.ts`
- **Then**: Generate modernization plan
- **Verify**: Preserves functionality, improves code quality

#### AT4: Large Feature
- **Given**: Complex multi-component feature description
- **Then**: Generate comprehensive plan or suggest breakdown
- **Verify**: Warning about scope, reasonable step count

#### AT5: Plan Validation
- **Given**: Generated plan with markers
- **Then**: All @file paths exist, @range valid, @cmd executable
- **Verify**: No validation warnings

## Metrics and Success Criteria

### Usage Metrics
- Plans generated per week
- Average plan size (step count)
- Marker accuracy rate
- User satisfaction

### Quality Metrics
- % of plans successfully executed
- % of plans requiring manual fixes
- Average time from plan to implementation
- User reported issues

### Performance Metrics
- Plan generation time by feature size
- Codebase scan time
- Validation time

## Open Questions

1. **Plan Execution**: Should the command support automatic plan execution?
2. **Plan Updates**: How to handle updating plans when requirements change?
3. **Collaboration**: Support for multi-developer plans with step assignments?
4. **Version Control**: Should plans be versioned alongside code?
5. **Templates**: Allow users to define custom plan templates?
6. **AI Agents**: Integration with future AI agents for plan execution?
7. **Estimation**: Auto-generate time estimates based on similar past work?
8. **Checkpoints**: Support for plan checkpoints and resume-from-step?

## Future Enhancements

### Phase 2: Interactive Planning
- Real-time plan refinement during implementation
- Step completion tracking
- Automatic plan updates based on discovered issues

### Phase 3: Plan Execution
- AI agent executes plans automatically
- Human-in-the-loop for approval
- Automatic validation after each step

### Phase 4: Learning
- Learn from execution to improve future plans
- Personalize to developer/team patterns
- Suggest optimizations based on history

## References

- `concept.md` - SpecBuddy concept vision
- `spec-creation-command.md` - Related command
- `CLAUDE.md` - Plugin architecture
- `.claude-plugin/plugin.json` - Command registration