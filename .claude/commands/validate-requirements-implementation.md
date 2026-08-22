---
description: Validate that code implements all business requirements and user flows
---

# Requirements Implementation Validator

Perform a code review focused on verifying that business requirements and user flows are correctly implemented.

## Scope

Identify the code to review and the business requirements/user stories it should satisfy.

## Review Process

### 1. Requirements Discovery

First, identify all applicable requirements:
- User stories or tickets referenced
- Acceptance criteria (if any)
- Business rules from documentation
- Implicit requirements from domain context
- Edge cases and error scenarios

### 2. Flow Analysis

Trace through the implementation to verify:
- Happy path works as expected
- All user flows are complete
- State transitions are correct
- Data flows through system correctly
- Integration points behave as expected

### 3. Business Logic Verification

- Business rules are correctly implemented
- Calculations and formulas are accurate
- Validation rules match requirements
- Edge cases are handled
- Error states produce correct behavior

### 4. Data Integrity

- Required fields are enforced
- Data transformations are correct
- Relationships are properly maintained
- Cascade behaviors are appropriate
- Audit trails where required

### 5. User Experience Flow

- User feedback is appropriate (success/error messages)
- Loading states are handled
- Error recovery is possible
- Navigation flow is correct

### 6. Gap Analysis

Identify any gaps between requirements and implementation:
- Missing functionality
- Partial implementations
- Deviations from requirements
- Undocumented behavior changes

## Output Format

### Requirements Mapping

| Requirement | Status | Evidence | Notes |
|-------------|--------|----------|-------|
| [requirement] | Met/Partial/Missing | [file:line or description] | [notes] |

### Flow Verification

| Flow | Status | Issues |
|------|--------|--------|
| [user flow] | Complete/Incomplete/Broken | [description] |

### Verdict: PASS or FAIL

### Gaps Identified

**Critical** (Blocks release)
- [Missing or broken requirement]

**Major** (Must address)
- [Partial implementation or deviation]

**Minor** (Should document)
- [Minor deviation or enhancement opportunity]

### Fix Checklist (if FAIL)

1. [Specific requirement gap with remediation]
2. [Specific requirement gap with remediation]

### Questions for Clarification

- [Any ambiguous requirements that need product/stakeholder input]

### Recommendations

- [Suggestions for improving requirement coverage or implementation]
