# Test Plan: [Test Scope Name]

## Metadata

**Test Plan ID:** TP-yyyyMMddHHmm-slug
**Last Updated:** [YYYYMMDD]
**Created:** [YYYYMMDD]
**Scope:** [Repository/Product | Module | Component | Service | Project `P{N}` | Release v[X.Y]]
**Scope Identifier:** [identifier — module/component/service name, P3, v2.5, Q3-launch, etc.]
**Owner:** [Test Lead name]

## Status

<!-- Choose one: Draft | In Review | Approved | Archived | Canceled -->

---

## 1. Introduction & Purpose

[1-2 paragraphs. Why this Test Plan exists, what it covers at a high level, who it's for. Keep this section tight — detail goes in the sections below.]

---

## 2. Scope

### In Scope

- [Feature, component, integration to be tested]
- [...]

### Out of Scope

- [Explicitly excluded area, with rationale]
- [...]

---

## 3. Test Objectives

[What success looks like for this test effort. Tie to program-level acceptance criteria, quality goals, and any compliance requirements.]

- [Objective: e.g., verify all P0 user journeys pass end-to-end]
- [Objective: e.g., performance targets — p99 < 500ms under the specified load profile]
- [Objective: e.g., zero Critical security findings]

---

## 4. Test Approach

### Test Levels

| Level | Owner | Tooling |
|-------|-------|---------|
| Unit | Developer | MSTest |
| Integration | Tester | Testcontainers |
| System / E2E | Tester | [tool] |
| User Acceptance | Product Owner / Stakeholder | [process] |

### Test Types

- **Functional:** [coverage strategy — risk-based, feature-coverage, etc.]
- **Non-functional:**
  - **Performance / Load:** [targets, tools, scenarios]
  - **Security:** [scope, tools — SAST/DAST/dependency scan]
  - **Accessibility:** [WCAG level, tools]
  - **Reliability / Chaos:** [approach, fault injection scope]
  - **Compatibility:** [browsers, OS, devices, versions]
- **Regression:** [strategy, automation level, frequency]

---

## 5. Test Environments

| Environment | Purpose | Data Strategy | Owner |
|-------------|---------|---------------|-------|
| Local | Developer self-test | [seed scripts, in-memory] | Developer |
| CI | Automated pipeline runs | [ephemeral / Testcontainers] | Platform |
| Staging | Pre-prod validation, UAT | [anonymized prod-derived / synthetic] | Platform |
| Production | Smoke, canary, synthetic monitoring only | [live] | SRE |

---

## 6. Test Data Strategy

- **Source:** [synthetic generated / anonymized production / hybrid]
- **PII handling:** [masking, tokenization, exclusion rules]
- **Refresh cadence:** [e.g., weekly snapshot from prod, anonymized]
- **Data volume targets:** [per environment, for performance testing]
- **Cleanup:** [post-run teardown, retention policy]

---

## 7. Entry Criteria

Testing begins when:

- [ ] Code builds clean in CI
- [ ] Unit tests pass
- [ ] Test environment provisioned and healthy
- [ ] Test data available and refreshed
- [ ] Required Test Cases drafted and approved
- [ ] Dependencies (services, integrations) available
- [ ] [other prerequisites]

---

## 8. Exit Criteria

Testing is complete when:

- [ ] Every in-scope acceptance criterion is mapped to a passing Test Case
- [ ] Zero open Blocker / Critical defects
- [ ] All performance targets met
- [ ] Security review signed off (if applicable)
- [ ] Accessibility targets met (if applicable)
- [ ] UAT sign-off captured
- [ ] [other criteria specific to this release]

---

## 9. Resources & Roles

| Role | Person(s) | Responsibility |
|------|-----------|----------------|
| Test Lead | [Name] | TP ownership, sign-off, coordination |
| Tester(s) | [Names] | TC authoring, execution, reporting |
| Developer(s) | [Names] | Unit tests, defect triage, fixes |
| Reviewer | [Name] | Quality gates, code review |
| Product Owner | [Name] | UAT sign-off, scope decisions |
| SRE / Platform | [Name] | Test environments, observability |

---

## 10. Schedule / Milestones

| Milestone | Target Date | Owner |
|-----------|-------------|-------|
| Test Plan approved | [YYYYMMDD] | Test Lead |
| Test environments ready | [YYYYMMDD] | Platform |
| Test Cases drafted | [YYYYMMDD] | Tester |
| Test execution start | [YYYYMMDD] | Tester |
| UAT start | [YYYYMMDD] | Product Owner |
| UAT complete | [YYYYMMDD] | Product Owner |
| Release sign-off | [YYYYMMDD] | Test Lead |

---

## 11. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [risk description] | High / Med / Low | High / Med / Low | [mitigation plan] |

---

## 12. Deliverables

- This Test Plan
- Test Cases documents (linked in section 13)
- Test execution reports (per environment / per cycle)
- Defect list and triage notes
- Final test summary report
- Release sign-off document

---

## 13. Test Cases Index

| Test Cases Document | Feature / Component | Owner | Status |
|---------------------|---------------------|-------|--------|
| [link to TC doc] | [feature] | [Tester name] | Drafted / Executing / Passed |

---

## 14. References

- [RFCs informing this plan]
- [ADRs of architectural relevance]
- [Design Docs]
- [Test implementation instructions](relative-link-to-tests-instructions) <!-- link-check-ignore: resolve .github/instructions/tests.instructions.md from the generated document location -->
- [External standards: IEEE 829, ISO/IEC/IEEE 29119, ISTQB syllabus, regulatory requirements]

---

## 15. Sign-off

| Name | Role | Date | Signature |
|------|------|------|-----------|
| [Name] | Test Lead | | |
| [Name] | Product Owner | | |
| [Name] | Engineering Lead | | |
