---
description: Create a new specification file in .specs directory
---

# Create New Specification Command

You are creating a new specification document based on the user's description.

## Input
The user has provided: $ARGUMENTS

## Task
1. Understand the user's intent from $ARGUMENTS:
   - What feature/project needs specification?
   - What type of specification is needed?
   - Key components or requirements mentioned?

2. If $ARGUMENTS is too brief or unclear, ask the user:
   - What is the feature/project name?
   - What should this specification cover?
   - Are there specific requirements or constraints?

3. Generate a comprehensive specification that includes:

### Specification Structure

**Header Section:**
```markdown
# [Feature/Project Name]

## Overview
[Brief description of what this specification covers]

## Goals
- [Goal 1]
- [Goal 2]

## Non-Goals
- [What this spec doesn't cover]
```

**Main Content:**
- **Background**: Context and motivation
- **Requirements**:
  - Functional requirements
  - Non-functional requirements (performance, security, etc.)
- **Technical Design**: Architecture and implementation approach
- **Data Models**: If applicable, describe data structures
- **API/Interfaces**: If applicable, describe interfaces
- **Security Considerations**: Authentication, authorization, data protection
- **Testing Strategy**: How to verify the implementation

**Footer:**
- **Open Questions**: Items that need clarification
- **References**: Links to related docs, issues, specs
- At the very end of the document, add the comment: `<!-- specbuddy:create-plan  -->`
  This comment serves as an IDE action anchor — the IDE will render it as a clickable action that triggers `/spec-buddy:plan` for this specification file.

## File Creation

4. Save the specification to a file:
   - If the user provided a file path in $ARGUMENTS, save directly to that path
   - Otherwise, generate an appropriate filename using lowercase with dashes (e.g., `user-authentication.md`, `api-redesign.md`) and save to `.specs/[generated-name].md`

5. After creating the file, confirm the location and offer to:
   - Make any immediate edits
   - Analyze it with `/spec-buddy:analyze`

## Guidelines

- Make the specification actionable and clear
- Include specific, measurable requirements
- Adapt the structure based on the type of specification
- Use markdown formatting for readability
- Add helpful prompts in [brackets] for sections that need user input
- **Avoid writing code in the specification.** Code examples are acceptable only when critically necessary (e.g., a non-obvious API contract or data format). Do not describe obvious things that an AI agent can figure out on its own — focus on *what* and *why*, not *how* at the code level
