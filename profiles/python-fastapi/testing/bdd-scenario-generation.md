# BDD Scenario Generation Skill

Generate Behavior-Driven Development (BDD) scenarios in Gherkin format during the design phase.

## Purpose

Support **acceptance testing** for FastAPI Python projects by:
1. Translating user stories into executable Gherkin scenarios
2. Defining acceptance criteria in Given-When-Then format
3. Creating test scenarios that validate end-to-end user flows
4. Providing clear, human-readable specifications for implementation
5. Establishing a contract between design and implementation

## When to Use

- **For PM-facing scenarios:** Use `skills/specify/bdd-scenarios.md` via `/specify` (Patterns 2 & 4, business language). `/specify` is mandatory before `/design`.
- **For engineer reference:** This skill documents all BDD patterns (technical language) for use during implementation via `/build`.

**Specific use cases:**
- **During design phase** - Generate scenarios from requirements/user stories
- **Complex user flows** - Multi-step interactions requiring clear specification
- **API contract validation** - Ensure endpoints meet user needs
- **Acceptance criteria** - Define testable success conditions
- **Stakeholder communication** - Provide non-technical readable tests

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
    And [another precondition]

  Scenario: [Happy path scenario name]
    Given [initial context]
    And [additional context]
    When [user action]
    And [additional action]
    Then [expected outcome]
    And [additional outcome]

  Scenario: [Error case scenario name]
    Given [error context]
    When [action that triggers error]
    Then [error handling outcome]
```

### Keywords

| Keyword | Purpose | Example |
|---------|---------|---------|
| **Feature** | High-level capability | `Feature: User Authentication` |
| **Background** | Common preconditions | `Given a user exists with email "test@example.com"` |
| **Scenario** | Specific test case | `Scenario: User logs in with valid credentials` |
| **Given** | Initial context/state | `Given I am not logged in` |
| **When** | User action/event | `When I submit login form with valid credentials` |
| **Then** | Expected outcome | `Then I should see my dashboard` |
| **And** | Additional steps | `And I should see a welcome message` |
| **But** | Contrasting outcome | `But I should not see login form` |

### Scenario Outlines (Data-Driven Tests)

For testing multiple variations:

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

**User Story:** As a user, I want to create a resource via API

```gherkin
Feature: Resource Creation
  Users can create resources through the API

  Scenario: Create resource with valid data
    Given I am authenticated as a standard user
    When I POST to "/api/resources" with:
      """json
      {
        "name": "Test Resource",
        "type": "standard"
      }
      """
    Then the response status should be 201
    And the response should include:
      | field | value |
      | id    | <uuid> |
      | name  | Test Resource |
      | type  | standard |
    And the resource should be stored in the database

  Scenario: Create resource with invalid data
    Given I am authenticated as a standard user
    When I POST to "/api/resources" with:
      """json
      {
        "name": "",
        "type": "invalid"
      }
      """
    Then the response status should be 400
    And the response should include validation errors:
      | field | error |
      | name  | Name cannot be empty |
      | type  | Invalid type value |
```

### Pattern 2: Multi-Step User Flow

**User Story:** As a user, I want to export my data

```gherkin
Feature: User Data Export
  Users can export their account data for backup purposes

  Background:
    Given I am logged in as "user@example.com"
    And my account has 1000 records

  Scenario: Export user data as CSV
    Given I am on the "Account Settings" page
    When I click "Export My Data"
    And I select format "CSV"
    And I click "Start Export"
    Then I should see "Export in progress"
    And I should receive an email notification when complete
    And the export should include all my account data
    And the export file should be in CSV format

  Scenario: Export with over 100k records
    Given my account has 150000 records
    When I request a data export
    Then the export should complete within 60 seconds
    And I should receive a download link
    And the link should expire after 24 hours
```

### Pattern 3: Error Handling

**User Story:** As a system, I want to handle errors gracefully

```gherkin
Feature: Error Handling
  System provides clear error messages for failure scenarios

  Scenario: Resource not found
    Given I am authenticated
    And no resource exists with id "nonexistent-id"
    When I GET "/api/resources/nonexistent-id"
    Then the response status should be 404
    And the response should include:
      """json
      {
        "error": "Resource not found",
        "detail": "Resource with id 'nonexistent-id' does not exist"
      }
      """

  Scenario: Unauthorized access
    Given I am not authenticated
    When I GET "/api/resources/protected-resource"
    Then the response status should be 401
    And the response should include:
      """json
      {
        "error": "Unauthorized",
        "detail": "Authentication required"
      }
      """
```

### Pattern 4: Authorization & Permissions

**User Story:** As an admin, I want to restrict access to sensitive operations

```gherkin
Feature: Resource Deletion Authorization
  Only admins can delete resources

  Background:
    Given a resource exists with id "resource-123"

  Scenario: Admin deletes resource
    Given I am authenticated as an admin user
    When I DELETE "/api/resources/resource-123"
    Then the response status should be 204
    And the resource "resource-123" should no longer exist

  Scenario: Standard user attempts to delete resource
    Given I am authenticated as a standard user
    When I DELETE "/api/resources/resource-123"
    Then the response status should be 403
    And the response should include:
      """json
      {
        "error": "Forbidden",
        "detail": "Insufficient permissions to delete resource"
      }
      """
    And the resource "resource-123" should still exist
```

### Pattern 5: Async Operations

**User Story:** As a user, I want to track long-running operations

```gherkin
Feature: Async Job Processing
  Users can initiate long-running jobs and track their status

  Scenario: Create and track async export job
    Given I am authenticated
    When I POST to "/api/users/export" with format "CSV"
    Then the response status should be 202
    And the response should include:
      | field      | pattern |
      | job_id     | <uuid>  |
      | status     | pending |
      | status_url | /api/users/export/<job_id> |

    When I GET the status_url after 5 seconds
    Then the response should include:
      | field    | value      |
      | status   | processing |
      | progress | 50         |

    When I GET the status_url after 30 seconds
    Then the response should include:
      | field        | value     |
      | status       | completed |
      | progress     | 100       |
      | download_url | <s3-url>  |

    When I GET the download_url
    Then I should receive a CSV file
    And the file should contain my user data
```

## Generation Process

### Step 1: Extract User Stories from Requirements

From PRD or design ticket, identify:
- **Actor:** Who performs the action (user, admin, system)
- **Action:** What they want to do (create, update, delete, view)
- **Outcome:** What they expect to happen (success, error, state change)

**Example:**
- PRD: "User can reorder assets within a content block"
- Actor: User (content creator)
- Action: Reorder assets (move asset to new position)
- Outcome: Assets displayed in new order

### Step 2: Identify Happy Path

The primary success scenario:

```gherkin
Scenario: User successfully reorders asset
  Given I am viewing a content block with 3 assets
  And the assets are in order: ["asset-1", "asset-2", "asset-3"]
  When I move "asset-3" before "asset-1"
  Then the assets should be in order: ["asset-3", "asset-1", "asset-2"]
  And the changes should be saved immediately
```

### Step 3: Identify Error Cases

What can go wrong?

```gherkin
Scenario: User attempts to reorder asset to invalid position
  Given I am viewing a content block with id "block-123"
  When I move asset "asset-1" before asset "asset-from-different-block"
  Then the response status should be 422
  And the response should include error "insert_before_id must be in same block"

Scenario: User attempts to reorder asset without permission
  Given I am viewing a content block I do not own
  When I attempt to move asset "asset-1"
  Then the response status should be 403
  And the response should include error "Insufficient permissions"
```

### Step 4: Identify Edge Cases

Boundary conditions:

```gherkin
Scenario: User moves asset to end of list
  Given I am viewing a content block with 3 assets
  When I move "asset-1" to the end (insert_before_id = null)
  Then the assets should be in order: ["asset-2", "asset-3", "asset-1"]

Scenario: User moves asset in single-asset block
  Given I am viewing a content block with 1 asset
  When I attempt to reorder the asset
  Then the operation should succeed with no changes
  And no API calls should be made
```

### Step 5: Map to API Contracts

Align scenarios with API design:

```gherkin
Scenario: Reorder asset API contract
  Given I am authenticated
  And a content block exists with:
    | block_id  | asset_1 | asset_2 | asset_3 |
    | block-123 | a1      | a2      | a3      |
  When I PATCH "/api/blocks/block-123/assets/a3/position" with:
    """json
    {
      "insert_before_id": "a1"
    }
    """
  Then the response status should be 204
  And GET "/api/blocks/block-123/assets" should return:
    """json
    {
      "assets": [
        {"id": "a3", "position": 1},
        {"id": "a1", "position": 2},
        {"id": "a2", "position": 3}
      ]
    }
    """
```

## Best Practices

### 1. Focus on User Behavior, Not Implementation

**Bad (Implementation-focused):**
```gherkin
Scenario: Service calls repository method
  Given a UserService instance
  When I call service.create_user()
  Then repository.add() should be called
```

**Good (User behavior-focused):**
```gherkin
Scenario: User registers successfully
  Given I am on the registration page
  When I submit valid registration information
  Then I should receive a confirmation email
  And I should be able to log in
```

### 2. Use Business Language, Not Technical Jargon

**Bad (Technical):**
```gherkin
Given a POST request to /api/v1/users with JSON payload
When the controller validates the DTO
Then the ORM should persist to PostgreSQL
```

**Good (Business language):**
```gherkin
Given I submit a registration form
When the information is valid
Then my account should be created
```

### 3. Keep Scenarios Independent

Each scenario should:
- Run independently (no dependencies on other scenarios)
- Set up its own context (Given steps)
- Clean up after itself (implicit in test framework)

### 4. Use Background for Common Setup

**Bad (Repeated setup):**
```gherkin
Scenario: User creates post
  Given I am logged in
  Given I have a valid auth token
  When I create a post
  ...

Scenario: User updates post
  Given I am logged in
  Given I have a valid auth token
  When I update a post
  ...
```

**Good (Background):**
```gherkin
Background:
  Given I am logged in
  And I have a valid auth token

Scenario: User creates post
  When I create a post
  ...

Scenario: User updates post
  When I update a post
  ...
```

### 5. Use Scenario Outlines for Variations

**Bad (Duplicated scenarios):**
```gherkin
Scenario: Export as CSV
  When I request export with format "csv"
  Then I receive a CSV file

Scenario: Export as JSON
  When I request export with format "json"
  Then I receive a JSON file
```

**Good (Scenario Outline):**
```gherkin
Scenario Outline: Export in different formats
  When I request export with format "<format>"
  Then I receive a <format> file

  Examples:
    | format |
    | csv    |
    | json   |
    | xml    |
```

### 6. One Feature = One File

Organize by feature domain:

```
features/
├── user_authentication.feature
├── user_registration.feature
├── data_export.feature
├── asset_management.feature
└── resource_permissions.feature
```

### 7. Limit Scenario Complexity

- **Max 5-7 steps per scenario** - If longer, consider splitting
- **Max 3 levels of And** - Too many Ands = scenario too complex
- **One action (When)** - Multiple actions = multiple scenarios

## Output Format

### During Design Phase

Save BDD scenarios alongside design documents:

```
.claude/design/
├── user-export-tdd.md              (Technical Design)
├── user-export-bdd.feature         (BDD Scenarios)
└── user-export-tickets/
    ├── SHRED-2119.md
    └── SHRED-2120.md
```

### Feature File Template

```gherkin
# features/[feature-name].feature
Feature: [Feature Name]
  [Multi-line feature description explaining the user value]

  Background:
    Given [common precondition]
    And [another common precondition]

  # Happy path
  Scenario: [Primary success case]
    Given [initial context]
    When [user action]
    Then [expected outcome]
    And [additional verification]

  # Error cases
  Scenario: [Error case 1]
    Given [error context]
    When [action that triggers error]
    Then [error handling]

  Scenario: [Error case 2]
    Given [another error context]
    When [action]
    Then [different error handling]

  # Edge cases
  Scenario: [Edge case 1]
    Given [boundary condition]
    When [action]
    Then [expected edge behavior]
```

## Integration with Design Workflow

### Stage 1: Requirements Analysis
Extract user stories and acceptance criteria from PRD.

### Stage 2: Identify Scenarios
- Happy path (primary user flow)
- Error cases (validation, authorization, not found)
- Edge cases (boundaries, empty states)

### Stage 3: Generate Gherkin
Write scenarios in Given-When-Then format.

### Stage 4: Map to API Contracts
Align scenarios with endpoint design from TDD.

### Stage 5: Save to Feature File
Output to `.claude/design/[feature-name]-bdd.feature`

### Stage 6: Review with Stakeholders
BDD scenarios serve as acceptance criteria for tickets.

## Tools Integration

### behave (Python BDD Framework)

```python
# features/steps/user_export_steps.py
from behave import given, when, then
import requests

@given('I am authenticated as "{email}"')
def step_given_authenticated(context, email):
    context.auth_token = get_auth_token(email)
    context.headers = {"Authorization": f"Bearer {context.auth_token}"}

@when('I POST to "{endpoint}" with format "{format}"')
def step_when_post_export(context, endpoint, format):
    context.response = requests.post(
        f"{context.base_url}{endpoint}",
        json={"format": format},
        headers=context.headers
    )

@then('the response status should be {status:d}')
def step_then_status(context, status):
    assert context.response.status_code == status
```

### pytest-bdd (Alternative)

```python
# tests/bdd/test_user_export.py
from pytest_bdd import scenarios, given, when, then

scenarios('features/user_export.feature')

@given('I am authenticated as "user@example.com"')
def authenticated_user(api_client):
    return api_client.authenticate('user@example.com')

@when('I request a data export')
def request_export(authenticated_user):
    return authenticated_user.post('/api/users/export', json={"format": "csv"})

@then('the export should complete within 60 seconds')
def check_export_completion(request_export, wait_for_job):
    job_id = request_export.json()['job_id']
    assert wait_for_job(job_id, timeout=60)
```

## Examples

### Example 1: Simple CRUD

```gherkin
Feature: User Profile Management
  Users can view and update their profile information

  Background:
    Given I am logged in as "user@example.com"

  Scenario: View my profile
    When I GET "/api/users/me"
    Then the response status should be 200
    And the response should include:
      | field | value             |
      | email | user@example.com  |
      | name  | Test User         |

  Scenario: Update my profile
    When I PATCH "/api/users/me" with:
      """json
      {
        "name": "Updated Name"
      }
      """
    Then the response status should be 200
    And my profile should show name "Updated Name"
```

### Example 2: Complex Multi-Step Flow

```gherkin
Feature: Async User Data Export
  Users can export their data and receive a download link

  Background:
    Given I am logged in as "user@example.com"
    And my account has 50000 records

  Scenario: Request and download export
    When I POST to "/api/users/export" with:
      """json
      {
        "format": "csv",
        "filters": {
          "date_range": "last_year"
        }
      }
      """
    Then the response status should be 202
    And the response should include fields:
      | field      |
      | job_id     |
      | status     |
      | status_url |

    When I poll the status_url every 5 seconds
    Then within 60 seconds the status should be "completed"
    And the response should include a "download_url"

    When I GET the download_url
    Then I should receive a file with content-type "text/csv"
    And the file should contain my filtered data
    And the file should have approximately 50000 rows
```

### Example 3: Authorization Matrix

```gherkin
Feature: Resource Access Control
  Different user roles have different access levels

  Background:
    Given the following users exist:
      | email           | role    |
      | admin@test.com  | admin   |
      | user@test.com   | user    |
      | guest@test.com  | guest   |
    And a resource exists with id "resource-123"

  Scenario Outline: User attempts to delete resource
    Given I am logged in as "<email>"
    When I DELETE "/api/resources/resource-123"
    Then the response status should be <status>
    And the resource should <exist_status>

    Examples:
      | email          | status | exist_status    |
      | admin@test.com | 204    | not exist       |
      | user@test.com  | 403    | still exist     |
      | guest@test.com | 403    | still exist     |
```

## Related Documentation

- **Testing Skill:** [skills/testing/SKILL.md](../../skills/testing/SKILL.md)
- **Behave Framework:** https://behave.readthedocs.io/
- **pytest-bdd:** https://pytest-bdd.readthedocs.io/
