---
name: spec-analyzer
description: Analyzes technical specifications and documentation for completeness, clarity, and best practices. Use when user asks to review, analyze, or check specifications.
---

# Specification Analyzer Skill

When analyzing a specification or technical document, perform the following checks:

## Structure Analysis
1. **Completeness**: Verify all essential sections are present
   - Overview/Introduction
   - Requirements
   - Technical details
   - API/Interface specifications (if applicable)
   - Dependencies
   - Examples or use cases

2. **Organization**: Check logical flow and structure
   - Clear hierarchy
   - Consistent formatting
   - Proper section numbering

## Content Quality
1. **Clarity**: Ensure requirements are:
   - Unambiguous
   - Testable
   - Measurable where appropriate
   - Written in clear, simple language

2. **Completeness**: Check that each requirement includes:
   - Purpose/rationale
   - Acceptance criteria
   - Edge cases (where relevant)

3. **Technical Accuracy**:
   - Consistent terminology
   - Accurate technical details
   - Valid code examples (if present)

## Best Practices
- Flag vague terms like "fast", "good", "user-friendly" without quantification
- Identify missing error handling specifications
- Note missing security considerations
- Check for inconsistencies between sections

## Output Format
Provide:
1. Overall assessment (brief summary)
2. Strengths of the specification
3. Issues found (categorized by severity: Critical, Important, Minor)
4. Specific recommendations for improvement
5. Examples of how to improve problematic sections

Focus on actionable feedback that helps improve the specification's quality.
