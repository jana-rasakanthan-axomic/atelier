# BDD Tools Integration

Tool-specific step definition patterns for implementing BDD scenarios in Python.

## behave (Python BDD Framework)

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

## pytest-bdd (Alternative)

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

## Related Documentation

- **Behave Framework:** https://behave.readthedocs.io/
- **pytest-bdd:** https://pytest-bdd.readthedocs.io/
