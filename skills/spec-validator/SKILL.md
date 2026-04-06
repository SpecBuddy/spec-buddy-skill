---
name: spec-validator
description: Validates specification documents against industry standards and best practices. Use when user needs to ensure a spec meets quality standards or check compliance.
---

# Specification Validator Skill

Validate technical specifications against established standards and best practices.

## Validation Criteria

### 1. Requirement Quality
Each requirement should be:
- **Specific**: Clearly defined scope and boundaries
- **Measurable**: Has clear success criteria
- **Achievable**: Technically feasible
- **Relevant**: Contributes to project goals
- **Testable**: Can be verified through testing

### 2. Documentation Standards
Check for:
- Consistent terminology throughout
- Properly formatted code examples
- Valid links and references
- Correct spelling and grammar
- Professional tone

### 3. Technical Completeness
Ensure specification includes:
- System architecture overview
- Data flow diagrams (when needed)
- API contracts with request/response examples
- Error codes and handling
- Performance requirements with metrics
- Security requirements
- Backward compatibility considerations

### 4. Risk Assessment
Identify:
- Missing dependencies
- Unclear acceptance criteria
- Potential security vulnerabilities
- Performance bottlenecks
- Scalability concerns
- Missing migration strategies

## Validation Process

1. **Parse the specification**: Extract all requirements, constraints, and technical details
2. **Check against standards**: Compare to best practices
3. **Flag violations**: Note specific issues with line numbers or section references
4. **Assess severity**: Critical, High, Medium, Low
5. **Provide guidance**: Suggest specific fixes

## Output Format

Provide a validation report with:
- Compliance score (percentage)
- List of violations by severity
- Specific locations of issues
- Recommended fixes
- Checklist of passed validations

Be precise and reference specific sections or lines when pointing out issues.
