# BDD Scenario Examples

Detailed Gherkin examples for common feature types.

## Example 1: Simple CRUD

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

## Example 2: Complex Multi-Step Flow

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

## Example 3: Authorization Matrix

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
