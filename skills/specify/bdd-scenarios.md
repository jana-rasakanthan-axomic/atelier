# BDD Scenario Generation (PM-Facing)

Generate Behavior-Driven Development (BDD) scenarios in Gherkin format using user-action language for PM review and approval.

**Maximum:** 30 BDD scenarios per feature. If more are needed, the feature should be split.

## Purpose

Support the **specification phase** by:
1. Translating user stories into Gherkin scenarios PMs can read and validate
2. Using business language throughout (no API paths, HTTP codes, or JSON)
3. Creating PM-approved acceptance criteria that feed into `/design`

## When to Use

- **For PM-facing scenarios:** Use this skill via `/specify` (Patterns A & B, business language)
- **For engineer-facing scenarios:** Use `skills/testing/bdd-scenario-generation.md` via `/design` (all patterns, technical language)
- **Skip BDD** for simple features where behavior is obvious, unit tests, or integration tests

## Key Differences from Engineering Version

| Aspect | This Skill (PM-facing) | Engineering Version |
|--------|----------------------|---------------------|
| **Audience** | Product Managers, Business Analysts | Engineers, QA |
| **Language** | User-action language | Technical (API, HTTP, JSON) |
| **Patterns** | A (User Flow) + B (Authorization) | All 5 patterns |
| **Given/When/Then** | Business actions | API calls and responses |

## Language Rules

| Engineering Language (NOT this) | PM Language (Use this) |
|-------------------------------|----------------------|
| `When I POST to "/api/users/export"` | `When I request a data export` |
| `Then the response status should be 403` | `Then I should see an access denied message` |
| `Given I have admin role JWT token` | `Given I am logged in as an administrator` |
| `And the response should be 202 Accepted` | `And I should see that my request is being processed` |

---

## Gherkin Structure

```gherkin
Feature: [Feature Name]
  [Feature description -- what user value it provides]

  Background:
    Given [common precondition for all scenarios]

  Scenario: [Descriptive scenario name]
    Given [initial context]
    When [user action]
    Then [expected outcome]
```

| Keyword | Purpose |
|---------|---------|
| **Feature** | High-level capability |
| **Background** | Common preconditions shared by all scenarios |
| **Scenario** | Specific test case |
| **Given/When/Then** | Context / Action / Outcome |
| **And/But** | Additional steps or contrasting outcomes |

---

## Scenario Patterns

### Pattern A: Multi-Step User Flow

```gherkin
Feature: [Feature Name]
  [User value description]

  Background:
    Given [common user context]

  Scenario: [Happy path]
    When [primary user action]
    And [optional secondary action]
    Then [expected success outcome]

  Scenario: [Edge case - large volume / boundary]
    Given [edge context]
    When [same action]
    Then [constrained outcome]

  Scenario: [Limit/denial case]
    Given [limiting context]
    When [same action]
    Then [denial with explanation]
```

### Pattern B: Authorization and Permissions

```gherkin
Feature: [Access Control for Feature]
  [Description of role-based access]

  Scenario Outline: Role-based access
    Given I am logged in as a <role>
    When I [attempt action]
    Then I should <result>

    Examples:
      | role          | result                              |
      | administrator | be able to [full access]            |
      | standard user | only [limited access]               |
      | guest         | see a message that login is required|
```

---

## Generation Process

1. **Extract user stories** from PRD: identify Actor, Action, Outcome
2. **Write happy path** scenario first (primary success case)
3. **Add error/denial cases** described in user terms (not HTTP codes)
4. **Add edge cases** for boundary conditions (large data, empty state, expired links)
5. **Use Background** for shared setup across scenarios
6. **Use Scenario Outline** for role/format variations instead of duplicating scenarios

### Scenario Complexity Limits

- Max 5-7 steps per scenario (split if longer)
- Max 3 levels of `And` (too many = too complex)
- One primary `When` action per scenario

---

## Output Format

```gherkin
# .claude/design/[feature-name]-bdd.feature
Feature: [Feature Name]
  [Multi-line feature description]

  Background:
    Given [common precondition]

  # Happy path
  Scenario: [Primary success case]
    ...

  # Additional success variations
  Scenario: [Variation]
    ...

  # Access control
  Scenario: [Authorized access]
    ...
  Scenario: [Denied access]
    ...

  # Edge cases
  Scenario: [Boundary condition]
    ...
```

---

## Related Documentation

- **Skill overview:** [SKILL.md](SKILL.md)
- **Business rules:** [business-rules.md](business-rules.md)
- **Engineering version:** [../testing/bdd-scenario-generation.md](../testing/bdd-scenario-generation.md)
