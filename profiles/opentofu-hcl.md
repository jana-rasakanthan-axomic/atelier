# Profile: opentofu-hcl

Infrastructure as Code with OpenTofu/Terraform and HCL (HashiCorp Configuration Language).

## Detection

```yaml
markers:
  required:
    - "*.tf"                    # At least one .tf file
  optional:
    - "terraform.tfstate"
    - ".terraform.lock.hcl"
    - "terragrunt.hcl"
    - "backend.tf"
```

---

## Stack

| Component       | Requirement                        |
|-----------------|------------------------------------|
| **Language**    | HCL (HashiCorp Configuration Language) |
| **Tool**        | OpenTofu >= 1.6 (or Terraform >= 1.5) |
| **Cloud**       | AWS (primary), with multi-cloud support |
| **State**       | Remote state (S3 + DynamoDB)       |
| **Linting**     | tflint                             |
| **Formatting**  | tofu fmt                           |
| **Testing**     | tofu test (built-in), or tftest    |
| **Security**    | tfsec, checkov                     |

---

## Workflow Override: Plan-Validate-Apply (NOT TDD)

**OpenTofu does NOT use TDD (Red-Green-Refactor).** Infrastructure follows a fundamentally different workflow.

### State Machine

```
WRITE_HCL --> VALIDATE --> PLAN --> STOP
```

| State | Actions | Gate |
|-------|---------|------|
| **WRITE_HCL** | Read plan, read pattern file, write `.tf` files | Files written |
| **VALIDATE** | `tofu fmt -check -recursive`, `tofu validate`, `tflint`, `tfsec .` | All pass (3 attempts max, then escalate) |
| **PLAN** | `tofu plan` | Plan succeeds (3 attempts max, then escalate) |
| **STOP** | Layer complete | `tofu apply` is NEVER run by the agent |

### What the Agent NEVER Does

- **Never runs `tofu apply`** -- requires human approval
- **Never modifies state files** -- managed by the backend
- **Never stores credentials in HCL** -- use variables, env vars, or AWS profiles

---

## Architecture Layers

Ordered outside-in (entry point first, individual resources last).

| # | Layer | Responsibility |
|---|-------|----------------|
| 1 | **Root Module** | Entry point, provider config, backend, top-level variable wiring |
| 2 | **Environment** | Environment-specific variable values (dev/staging/prod tfvars) |
| 3 | **Module** | Reusable infrastructure components, encapsulated resource groups |
| 4 | **Resource** | Individual cloud resources, lifecycle rules, dependencies |

**Build order:** Root Module --> Environment --> Module --> Resource

**Note:** Always run `tofu init` before `tofu validate` or `tofu plan` when providers or modules change.

---

## Quality Tools

```yaml
tools:
  test_runner:
    command: "tofu test"
    single_file: "tofu test -filter={file}"
    verbose: "tofu test -verbose"
  linter:
    command: "tflint"
  type_checker:
    command: "tofu validate"
  formatter:
    command: "tofu fmt -recursive"
    check: "tofu fmt -check -recursive"
  security:
    command: "tfsec ."
```

### Verify Step (run after every layer)

```bash
tofu fmt -check -recursive && tofu validate && tflint && tfsec .
```

---

## Allowed Bash Tools

```
Bash(tofu:*), Bash(tflint:*), Bash(tfsec:*), Bash(git:*), Bash(aws:*)
```

---

## Test Patterns

| Layer | Test Method | Tool |
|-------|-------------|------|
| Root Module | validate + plan | tofu validate/plan |
| Environment | plan per env | tofu plan |
| Module | tofu test | tofu test |
| Resource | validate + plan | tofu validate/plan |

### Test Organization

```yaml
test_patterns:
  unit:
    location: "tests/"
    naming: "*.tftest.hcl"
  validation:
    markers: ["tofu validate"]
  plan:
    markers: ["tofu plan"]
```

### Test File Structure

```hcl
# tests/vpc_test.tftest.hcl
variables {
  vpc_cidr    = "10.0.0.0/16"
  environment = "test"
}

run "creates_vpc_with_correct_cidr" {
  command = plan
  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block does not match expected value"
  }
}
```

Test naming: `{module_name}_test.tftest.hcl` (e.g., `vpc_test.tftest.hcl`, `iam_roles_test.tftest.hcl`)

---

## Naming Conventions

```yaml
naming:
  files: "snake_case.tf"
  resources: "snake_case (aws_instance.web_server)"
  modules: "snake_case"
  variables: "snake_case"
  outputs: "snake_case"
  locals: "snake_case"
  data_sources: "snake_case (data.aws_ami.ubuntu)"
  test_files: "*.tftest.hcl"
  environments: "dev, staging, prod"
  tags: "PascalCase keys (Name, Environment, ManagedBy)"
```

---

## Code Patterns

> See [patterns/module.md](./opentofu-hcl/patterns/module.md) for reusable module patterns and examples.

> See [patterns/resource.md](./opentofu-hcl/patterns/resource.md) for resource definitions with lifecycle and depends_on.

> See [patterns/variables.md](./opentofu-hcl/patterns/variables.md) for variable definitions with type constraints and validation.

> See [patterns/outputs.md](./opentofu-hcl/patterns/outputs.md) for output definitions with sensitivity and splat expressions.

### Key Rules Summary

- **Root Module:** Pin `required_version`, use `required_providers` with version constraints, enable `default_tags`, wire modules via outputs
- **Modules:** Own `main.tf` + `variables.tf` + `outputs.tf`, no hardcoded values, tag every resource
- **Variables:** Every variable has `description` and `type`, add `validation` for constrained values, mark sensitive values
- **Outputs:** Every output has `description`, mark sensitive with `sensitive = true`, use splat for lists

---

## Style Limits

```yaml
limits:
  max_resource_per_file: 5
  max_file_lines: 200
  max_module_resources: 10
  max_variable_files: 1
  max_nesting_depth: 2
```

Split into separate `.tf` files or modules when limits are exceeded. Flatten deep nesting with locals.

---

## Dependencies

| Field | Value |
|-------|-------|
| Manager | `tofu` |
| Install | `tofu init` |
| Lock file | `.terraform.lock.hcl` |

---

## Project Structure

```
project-root/
  main.tf               # Root module entry point
  variables.tf          # Input variables
  outputs.tf            # Output values
  providers.tf          # Provider configuration
  backend.tf            # State backend config
  versions.tf           # Required provider versions
  modules/{name}/       # main.tf, variables.tf, outputs.tf per module
  environments/{env}/   # terraform.tfvars per environment
  tests/                # {module}_test.tftest.hcl
```

---

## Profile Metadata

```yaml
metadata:
  name: opentofu-hcl
  version: "1.0.0"
  description: "Infrastructure as Code with OpenTofu/Terraform and HCL"
  tags: ["hcl", "opentofu", "terraform", "aws", "infrastructure", "iac"]
```
