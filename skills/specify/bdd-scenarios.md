# BDD Scenario Generation (PM-Facing)

Generate Behavior-Driven Development (BDD) scenarios in Gherkin format using user-action language for PM review and approval.

## Purpose

Support the **specification phase** by:
1. Translating user stories into Gherkin scenarios PMs can read and validate
2. Using business language throughout (no API paths, HTTP codes, or JSON)
3. Creating PM-approved acceptance criteria that feed into `/design`

## When to Use

- **For PM-facing scenarios:** Use this skill via `/specify` (Patterns 2 & 4, business language)
- **For engineer-facing scenarios:** Use `skills/testing/bdd-scenario-generation.md` via `/design` (all patterns, technical language)

## When NOT to Use

- **Unit tests** — Use pytest with AAA pattern instead
- **Integration tests** — Use pytest with test fixtures instead
- **Technical API validation** — Use the engineering BDD skill
- **Simple features** — Skip BDD if behavior is obvious

## Key Differences from Engineering Version

| Aspect | This Skill (PM-facing) | Engineering Version |
|--------|----------------------|---------------------|
| **Audience** | Product Managers, Business Analysts | Engineers, QA |
| **Language** | User-action language | Technical language (API, HTTP, JSON) |
| **Patterns used** | Pattern 2 (User Flow) + Pattern 4 (Authorization) | All 5 patterns |
| **Excluded** | Pattern 1 (API Request/Response), Pattern 3 (Error Handling), Pattern 5 (Async Operations) | None excluded |
| **Given/When/Then** | Business actions | API calls and responses |

## Language Rules

**Always use user-action language:**

| Engineering Language (NOT this) | PM Language (Use this) |
|-------------------------------|----------------------|
| `When I POST to "/api/users/export"` | `When I request a data export` |
| `Then the response status should be 403` | `Then I should see an access denied message` |
| `Given I have admin role JWT token` | `Given I am logged in as an administrator` |
| `Then the response should include job_id` | `Then I should see a confirmation that my export has started` |
| `When I GET the status_url after 5 seconds` | `When I check on my export progress` |
| `And the response should be 202 Accepted` | `And I should see that my request is being processed` |
| `Given a POST request with JSON payload` | `Given I submit the registration form` |
| `Then the ORM should persist to PostgreSQL` | `Then my account should be created` |

## Gherkin Basics

### Structure

```gherkin
Feature: [Feature Name]
  [Feature description — what user value it provides]

  Background:
    Given [common precondition for all scenarios]

  Scenario: [Descriptive scenario name]
    Given [initial context]
    When [user action]
    Then [expected outcome]
```

### Keywords

| Keyword | Purpose | Example |
|---------|---------|---------|
| **Feature** | High-level capability | `Feature: User Data Export` |
| **Background** | Common preconditions | `Given I am logged in as a standard user` |
| **Scenario** | Specific test case | `Scenario: User exports their data as CSV` |
| **Given** | Initial context/state | `Given I have 1000 records in my account` |
| **When** | User action | `When I request a data export in CSV format` |
| **Then** | Expected outcome | `Then I should receive a download link` |
| **And** | Additional steps | `And the link should be available for 24 hours` |
| **But** | Contrasting outcome | `But I should not see other users' data` |

## Scenario Patterns

### Pattern A: Multi-Step User Flow

For features involving multiple user interactions or steps.

```gherkin
Feature: User Data Export
  Users can export their account data for backup purposes

  Background:
    Given I am logged in as a standard user
    And my account has 1000 records

  Scenario: Export data as CSV
    When I request a data export
    And I select CSV as the format
    Then I should see a confirmation that my export has started
    And I should be notified when the export is ready
    And I should receive a download link
    And the download should contain all my account data in CSV format

  Scenario: Export with a very large account
    Given my account has 100,000 records
    When I request a data export
    Then the export should complete within 60 seconds
    And I should receive a download link
    And the link should be available for 24 hours

  Scenario: Attempt to export when daily limit is reached
    Given I have already exported 5 times today
    When I request another data export
    Then I should see a message that I've reached my daily export limit
    And I should be told when I can export again
```

### Pattern B: Authorization & Permissions

For features with role-based access or permission rules.

```gherkin
Feature: Account Data Access Control
  Different user roles have different levels of access to account data

  Background:
    Given there are multiple user accounts in the system

  Scenario: Standard user accesses their own data
    Given I am logged in as a standard user
    When I request to view my account data
    Then I should see my own account information
    But I should not see any other user's data

  Scenario: Administrator accesses any user's data
    Given I am logged in as an administrator
    When I request to view another user's account data
    Then I should be able to see that user's information

  Scenario: Standard user attempts to access another user's data
    Given I am logged in as a standard user
    When I attempt to view another user's account data
    Then I should see an access denied message
    And the other user's data should remain hidden

  Scenario Outline: Role-based access to export feature
    Given I am logged in as a <role>
    When I request to export account data
    Then I should <result>

    Examples:
      | role           | result                                        |
      | administrator  | be able to export any user's data             |
      | standard user  | only be able to export my own data            |
      | guest          | see a message that this feature requires login |
```

## Generation Process

### Step 1: Extract User Stories from Requirements

From PRD or approved business rules, identify:
- **Actor:** Who performs the action (user, admin, guest)
- **Action:** What they want to do (export, view, update)
- **Outcome:** What they expect to happen (success, notification, error message)

### Step 2: Identify Happy Path

The primary success scenario — what happens when everything goes right.

```gherkin
Scenario: User successfully exports their data
  Given I am logged in as a standard user
  And my account has records
  When I request a data export in CSV format
  Then I should receive a download link within 60 seconds
  And the file should contain all my account data
```

### Step 3: Identify Error and Denial Cases

What happens when something goes wrong or access is denied — described in user terms.

```gherkin
Scenario: User attempts an action beyond their permissions
  Given I am logged in as a standard user
  When I attempt to export another user's data
  Then I should see an access denied message

Scenario: User exceeds their usage limit
  Given I have reached my daily export limit
  When I request another export
  Then I should see a message explaining the limit
  And I should be told when I can try again
```

### Step 4: Identify Edge Cases

Boundary conditions described in business terms.

```gherkin
Scenario: User exports when account has no data
  Given I am logged in as a new user
  And my account has no records yet
  When I request a data export
  Then I should see a message that there is no data to export

Scenario: User accesses an expired download link
  Given I previously requested a data export
  And more than 24 hours have passed since the export
  When I try to download the export file
  Then I should see a message that the link has expired
  And I should be offered the option to request a new export
```

## Best Practices

### 1. Focus on User Behavior, Not Implementation

**Not this:**
```gherkin
Scenario: Service calls repository method
  Given a UserService instance
  When I call service.create_user()
  Then repository.add() should be called
```

**This:**
```gherkin
Scenario: New user registers successfully
  Given I am on the registration page
  When I submit valid registration information
  Then my account should be created
  And I should receive a welcome email
```

### 2. Keep Scenarios Independent

Each scenario should:
- Run independently (no dependencies on other scenarios)
- Set up its own context (Given steps)
- Tell a complete story

### 3. Use Background for Common Setup

```gherkin
Background:
  Given I am logged in as a standard user
  And my account is in good standing

Scenario: User performs action A
  When I do action A
  ...

Scenario: User performs action B
  When I do action B
  ...
```

### 4. Use Scenario Outlines for Variations

```gherkin
Scenario Outline: Export in different formats
  When I request a data export in <format> format
  Then I should receive a file in <format> format

  Examples:
    | format |
    | CSV    |
    | JSON   |
```

### 5. One Feature Per File

Organize by feature domain:
```
.claude/design/
├── user-export-bdd.feature
├── user-registration-bdd.feature
└── account-settings-bdd.feature
```

### 6. Limit Scenario Complexity

- **Max 5-7 steps per scenario** — if longer, consider splitting
- **Max 3 levels of And** — too many Ands means the scenario is too complex
- **One primary action (When)** — multiple actions should be multiple scenarios

## Limits

- Maximum 30 BDD scenarios per feature
- If more than 30 scenarios are needed, the feature should likely be split

## Output Format

```gherkin
# .claude/design/[feature-name]-bdd.feature
Feature: [Feature Name]
  [Multi-line feature description explaining the user value]

  Background:
    Given [common precondition]

  # Happy path
  Scenario: [Primary success case]
    Given [initial context]
    When [user action]
    Then [expected outcome]

  # Additional success cases
  Scenario: [Variation of success]
    Given [different context]
    When [user action]
    Then [expected outcome]

  # Access control
  Scenario: [Authorized access]
    Given [authorized user context]
    When [action]
    Then [allowed outcome]

  Scenario: [Denied access]
    Given [unauthorized user context]
    When [same action]
    Then [denied outcome]

  # Edge cases
  Scenario: [Boundary condition]
    Given [edge context]
    When [action]
    Then [edge behavior]
```

## Related Documentation

- **Skill overview:** [skills/specify/SKILL.md](SKILL.md)
- **Business rules:** [skills/specify/business-rules.md](business-rules.md)
- **Engineering version:** [skills/testing/bdd-scenario-generation.md](../testing/bdd-scenario-generation.md)
