# BDD Scenario Generation Skill

Generate Behavior-Driven Development (BDD) scenarios in Gherkin format during the design phase.

## Purpose

Support **acceptance testing** for FastAPI Python projects by:
1. Translating user stories into executable Gherkin scenarios
2. Defining acceptance criteria in Given-When-Then format
3. Creating test scenarios that validate end-to-end user flows
4. Establishing a contract between design and implementation

## When to Use

- **For PM-facing scenarios:** Use `skills/specify/bdd-scenarios.md` via `/specify` (Patterns 2 & 4, business language). `/specify` is mandatory before `/design`.
- **For engineer reference:** This skill documents all BDD patterns (technical language) for use during implementation via `/build`.

**Specific use cases:** design phase scenario generation, complex user flows, API contract validation, acceptance criteria, stakeholder communication.

## When NOT to Use

- **Unit tests** - Use pytest with AAA pattern instead
- **Integration tests** - Use pytest with test fixtures instead
- **Implementation details** - BDD focuses on user behavior, not internal logic
- **Simple CRUD operations** - Overkill for straightforward operations

## Gherkin Basics

### Structure

```gherkin
Feature: [Feature Name]
  [Feature description - what user value it provides]

  Background:
    Given [common precondition for all scenarios]

  Scenario: [Happy path scenario name]
    Given [initial context]
    When [user action]
    Then [expected outcome]

  Scenario: [Error case scenario name]
    Given [error context]
    When [action that triggers error]
    Then [error handling outcome]
```

### Keywords

| Keyword | Purpose |
|---------|---------|
| **Feature** | High-level capability being described |
| **Background** | Common preconditions shared by all scenarios |
| **Scenario** | A specific test case with context, action, outcome |
| **Given** | Initial context or state |
| **When** | User action or event trigger |
| **Then** | Expected outcome or assertion |

Use **And** / **But** to chain additional steps within Given, When, or Then.

### Scenario Outlines (Data-Driven Tests)

```gherkin
Scenario Outline: [Template scenario name]
  Given [context with <placeholder>]
  When [action with <placeholder>]
  Then [outcome with <placeholder>]

  Examples:
    | placeholder1 | placeholder2 | expected_result |
    | value1       | value2       | result1         |
    | value3       | value4       | result2         |
```

## BDD Scenario Patterns

### Pattern 1: API Request/Response

```gherkin
Feature: Resource Creation
  Users can create resources through the API

  Scenario: Create resource with valid data
    Given I am authenticated as a standard user
    When I POST to "/api/resources" with:
      """json
      { "name": "Test Resource", "type": "standard" }
      """
    Then the response status should be 201
    And the response should include:
      | field | value         |
      | name  | Test Resource |
      | type  | standard      |

  Scenario: Create resource with invalid data
    Given I am authenticated as a standard user
    When I POST to "/api/resources" with:
      """json
      { "name": "", "type": "invalid" }
      """
    Then the response status should be 400
    And the response should include validation errors
```

### Pattern 2: Multi-Step User Flow

```gherkin
Feature: User Data Export
  Users can export their account data for backup purposes

  Background:
    Given I am logged in as "user@example.com"
    And my account has 1000 records

  Scenario: Export user data as CSV
    When I click "Export My Data" and select format "CSV"
    Then I should see "Export in progress"
    And I should receive an email notification when complete
    And the export file should be in CSV format

  Scenario: Export with over 100k records
    Given my account has 150000 records
    When I request a data export
    Then the export should complete within 60 seconds
    And the download link should expire after 24 hours
```

### Pattern 3: Error Handling

```gherkin
Feature: Error Handling
  System provides clear error messages for failure scenarios

  Scenario: Resource not found
    Given I am authenticated
    When I GET "/api/resources/nonexistent-id"
    Then the response status should be 404
    And the response should include error "Resource not found"

  Scenario: Unauthorized access
    Given I am not authenticated
    When I GET "/api/resources/protected-resource"
    Then the response status should be 401
```

### Pattern 4: Authorization & Permissions

```gherkin
Feature: Resource Deletion Authorization
  Only admins can delete resources

  Background:
    Given a resource exists with id "resource-123"

  Scenario: Admin deletes resource
    Given I am authenticated as an admin user
    When I DELETE "/api/resources/resource-123"
    Then the response status should be 204
    And the resource should no longer exist

  Scenario: Standard user attempts to delete resource
    Given I am authenticated as a standard user
    When I DELETE "/api/resources/resource-123"
    Then the response status should be 403
    And the resource should still exist
```

## Generation Process

### Step 1: Extract User Stories

From PRD or design ticket, identify **Actor** (who), **Action** (what), and **Outcome** (expected result).

### Step 2: Identify Happy Path

Write the primary success scenario first.

### Step 3: Identify Error Cases

What can go wrong? Validation failures, authorization denied, resource not found.

### Step 4: Identify Edge Cases

Boundary conditions: empty lists, single items, maximum limits, null values.

### Step 5: Map to API Contracts

Align scenarios with endpoint design -- match HTTP methods, paths, request/response shapes.

## Best Practices Checklist

- [ ] Scenarios focus on **user behavior**, not implementation details
- [ ] Use **business language**, not technical jargon (no "ORM", "DTO", "controller")
- [ ] Each scenario is **independent** -- sets up its own context via Given steps
- [ ] Use **Background** for setup shared by all scenarios in a feature
- [ ] Use **Scenario Outlines** for variations instead of duplicating scenarios
- [ ] **One feature per file** -- organize by domain (`user_authentication.feature`)
- [ ] **Max 5-7 steps** per scenario; one When action per scenario
- [ ] **One feature = one `.feature` file** in `features/` directory

## Integration with Design Workflow

1. **Requirements Analysis** -- Extract user stories and acceptance criteria from PRD
2. **Identify Scenarios** -- Happy path, error cases, edge cases
3. **Generate Gherkin** -- Write Given-When-Then scenarios
4. **Map to API Contracts** -- Align with endpoint design
5. **Save** -- Output to `.claude/design/[feature-name]-bdd.feature`
6. **Review** -- BDD scenarios serve as acceptance criteria for tickets

> See [bdd-tools-integration.md](./bdd-tools-integration.md) for behave and pytest-bdd step definition patterns.

> See [bdd-examples.md](./bdd-examples.md) for detailed CRUD, multi-step flow, and authorization matrix examples.
