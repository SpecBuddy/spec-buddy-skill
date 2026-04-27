---
name: new
description: Create a new specification document in `.specs/` from a feature description, project idea, or requirements brief. Produces a comprehensive markdown spec covering goals, requirements, technical design, and open questions, ready to drive planning and implementation.
triggers:
  - "create a new specification"
  - "draft a spec for this feature"
  - "start a new design doc"
  - "write a spec for ..."
  - "I want to specify a new feature"
  - "generate a specification document"
---

# Create New Specification

You are creating a new specification document based on the user's description.

## Input Elicitation

Determine the user's intent from the request. You need to know:
- What feature, project, or change needs to be specified?
- What type of specification is appropriate (feature spec, refactoring spec, system design, etc.)?
- Any key components, constraints, or requirements the user has already mentioned?
- An optional target file path; if not given, you will derive one.

If the request is too brief or unclear, ask the user concise clarifying questions before proceeding:
- What is the feature or project name?
- What should this specification cover (and explicitly not cover)?
- Are there specific requirements, constraints, or stakeholders to keep in mind?

Do not over-interrogate — gather the minimum needed to write a useful first draft.

## Specification Structure

Generate a comprehensive specification with the following structure.

**Header:**

```markdown
# [Feature/Project Name]

## Overview
[Brief description of what this specification covers]

## Goals
- [Goal 1]
- [Goal 2]

## Non-Goals
- [What this spec does not cover]
```

**Main content** (adapt sections to the type of spec):
- **Background** — context and motivation
- **Requirements**
  - Functional requirements
  - Non-functional requirements (performance, security, observability, etc.)
- **Technical Design** — architecture and implementation approach
- **Data Models** — describe data structures if applicable
- **API/Interfaces** — describe interfaces if applicable
- **Security Considerations** — authentication, authorization, data protection
- **Testing Strategy** — how the implementation will be verified

**Footer:**
- **Open Questions** — items that still need clarification
- **References** — links to related docs, issues, prior specs
- At the very end of the document, add the comment exactly as shown:

  ```
  <!-- specbuddy:create-plan  -->
  ```

  This comment is an IDE action anchor — the IDE renders it as a clickable action that triggers plan generation for this specification. It must appear verbatim, with no attributes or modifications.

## File Creation

Save the specification to a markdown file:
- If the user supplied a file path, save directly to that path.
- Otherwise, derive an appropriate filename from the feature name using lowercase kebab-case (for example `user-authentication.md`, `api-redesign.md`) and save to `.specs/<generated-name>.md`.

After creating the file, confirm the saved location and offer to:
- Make any immediate edits the user wants.
- Move on to generating an implementation plan from the new spec.

## Authoring Guidelines

- Make the specification actionable and clear.
- Include specific, measurable requirements.
- Adapt the section list to the kind of specification (skip sections that do not apply rather than padding).
- Use clean markdown formatting for readability.
- Add helpful prompts in `[brackets]` for any sections where the user still needs to supply input.
- **Avoid writing code in the specification.** Code examples are acceptable only when critically necessary (for example a non-obvious API contract or data format). Do not describe obvious things an implementing agent can figure out on its own — focus on *what* and *why*, not *how* at the code level.
