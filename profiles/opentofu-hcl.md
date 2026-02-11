# Profile: opentofu-hcl

Infrastructure as Code with OpenTofu/Terraform and HCL (HashiCorp Configuration Language).

## Detection

How Atelier identifies a project as opentofu-hcl:

```yaml
markers:
  required:
    - "*.tf"                    # At least one .tf file
  content_match: []             # No content match needed
  optional:
    - "terraform.tfstate"
    - ".terraform.lock.hcl"
    - "terragrunt.hcl"
    - "backend.tf"
```

If any `*.tf` file exists in the project root, this profile activates.

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

**OpenTofu does NOT use TDD (Red-Green-Refactor).** Infrastructure as Code follows a fundamentally different workflow because you cannot "run" infrastructure in a unit test the same way you run application code.

Instead, OpenTofu uses the **Plan-Validate-Apply** workflow:

```
1. PLAN      -- Write HCL, run `tofu plan` to preview changes
2. VALIDATE  -- Run `tofu validate`, `tflint`, `tfsec` to check correctness and security
3. APPLY     -- Run `tofu apply` (with approval) to create/modify infrastructure
```

### State Machine (replaces TDD states)

```
+-------------------------------------------------------------+
|  STATE 1: WRITE_HCL                                         |
|  Actions:                                                    |
|    - Read requirements / plan                                |
|    - Read pattern: profiles/opentofu-hcl/patterns/{layer}.md |
|    - Write .tf files                                         |
|  Output: "HCL written: {file}"                               |
|  Next State: VALIDATE                                        |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|  STATE 2: VALIDATE                                           |
|  Actions:                                                    |
|    - Run: tofu fmt -check -recursive                         |
|    - Run: tofu validate                                      |
|    - Run: tflint                                             |
|    - Run: tfsec .                                            |
|  Gate Check:                                                 |
|    All pass --> Output: "Validation passed" --> PLAN         |
|    Any fail --> Fix issues, return to WRITE_HCL              |
|                                                              |
|  BLOCKED: Cannot proceed until all checks pass               |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|  STATE 3: PLAN                                               |
|  Actions:                                                    |
|    - Run: tofu plan                                          |
|  Gate Check:                                                 |
|    Plan succeeds --> Output: "Plan confirmed" --> STOP       |
|    Plan fails    --> Fix issues, return to WRITE_HCL         |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|  STATE 4: STOP                                               |
|  Output: "Layer complete. Ready for next layer or apply."    |
|  Note: `tofu apply` is NEVER run by the agent.              |
|        Apply requires human approval.                        |
+-------------------------------------------------------------+
```

### State Transition Rules

| Current State | Condition | Next State |
|---------------|-----------|------------|
| WRITE_HCL | Files written | VALIDATE |
| VALIDATE | All checks pass | PLAN |
| VALIDATE | Any check fails (attempt < 3) | WRITE_HCL (fix) |
| VALIDATE | Any check fails (attempt = 3) | ESCALATE |
| PLAN | Plan succeeds | STOP |
| PLAN | Plan fails (attempt < 3) | WRITE_HCL (fix) |
| PLAN | Plan fails (attempt = 3) | ESCALATE |

### What the Agent NEVER Does

- **Never runs `tofu apply`** -- applying infrastructure changes requires human approval
- **Never modifies state files** -- state is managed by the backend
- **Never stores credentials in HCL** -- use variables, environment variables, or AWS profiles

---

## Architecture Layers

Ordered outside-in (entry point first, individual resources last).

| # | Layer               | Responsibility                                                                 |
|---|---------------------|--------------------------------------------------------------------------------|
| 1 | **Root Module**     | Entry point, provider configuration, backend config, top-level variable wiring |
| 2 | **Environment**     | Environment-specific variable values (dev/staging/prod tfvars)                 |
| 3 | **Module**          | Reusable infrastructure components, encapsulated resource groups               |
| 4 | **Resource**        | Individual cloud resources within modules, lifecycle rules, dependencies       |

---

## Build Order

```
Root Module --> Environment --> Module --> Resource
```

**Rationale:** Start from the entry point that wires everything together, define environment-specific configurations, then build reusable modules, and finally define individual resources within those modules.

**Note:** Always run `tofu init` before `tofu validate` or `tofu plan` when providers or modules change.

---

## Quality Tools

```yaml
tools:
  test_runner:
    command: "tofu test"
    single_file: "tofu test -filter={file}"
    verbose: "tofu test -verbose"
    coverage: ""                  # No coverage concept for IaC
    confirm_red: ""               # Not applicable (Plan-Validate-Apply workflow)
    confirm_green: ""             # Not applicable (Plan-Validate-Apply workflow)

  linter:
    command: "tflint"
    fix: ""                       # tflint does not auto-fix

  type_checker:
    command: "tofu validate"      # Validates HCL syntax and type constraints

  formatter:
    command: "tofu fmt -recursive"
    check: "tofu fmt -check -recursive"

  security:
    command: "tfsec ."
    fix: ""                       # tfsec does not auto-fix
```

### Verify Step (run after every layer)

```bash
tofu fmt -check -recursive && tofu validate && tflint && tfsec .
```

All four must pass before a layer is considered complete.

---

## Allowed Bash Tools

For use in command and agent frontmatter `allowed-tools` fields:

```
Bash(tofu:*), Bash(tflint:*), Bash(tfsec:*), Bash(git:*), Bash(aws:*)
```

---

## Test Patterns

### What Gets Validated (Plan-Validate-Apply Applicability)

| Layer            | Test Method       | Tool              | Rationale                          |
|------------------|-------------------|-------------------|------------------------------------|
| Root Module      | validate + plan   | tofu validate/plan| Confirms wiring and provider config |
| Environment      | plan per env      | tofu plan         | Confirms env-specific values work  |
| Module           | tofu test         | tofu test         | Unit tests for module behavior     |
| Resource         | validate + plan   | tofu validate/plan| Confirms resource configuration    |

### Test Organization

```yaml
test_patterns:
  unit:
    location: "tests/"
    naming: "*.tftest.hcl"
    pattern: "run blocks with assert conditions"
  validation:
    location: "."
    naming: "N/A"
    markers: ["tofu validate"]
  plan:
    location: "."
    naming: "N/A"
    markers: ["tofu plan"]
```

### Test File Structure

```hcl
# tests/vpc_test.tftest.hcl

variables {
  vpc_cidr = "10.0.0.0/16"
  environment = "test"
}

run "creates_vpc_with_correct_cidr" {
  command = plan

  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block does not match expected value"
  }
}

run "tags_include_environment" {
  command = plan

  assert {
    condition     = aws_vpc.main.tags["Environment"] == "test"
    error_message = "VPC missing Environment tag"
  }
}
```

### Test Naming

```
{module_name}_test.tftest.hcl
```

Examples:
- `vpc_test.tftest.hcl`
- `iam_roles_test.tftest.hcl`
- `s3_buckets_test.tftest.hcl`

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

### Root Module Pattern

```hcl
# main.tf -- Root module entry point
terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket         = "myproject-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "opentofu"
    }
  }
}

module "networking" {
  source      = "./modules/networking"
  vpc_cidr    = var.vpc_cidr
  environment = var.environment
}

module "compute" {
  source      = "./modules/compute"
  vpc_id      = module.networking.vpc_id
  subnet_ids  = module.networking.private_subnet_ids
  environment = var.environment
}
```

Rules:
- Pin `required_version` to a minimum OpenTofu/Terraform version
- Use `required_providers` with version constraints (`~>` for minor version flexibility)
- Enable `default_tags` on the provider for consistent tagging
- Backend config uses S3 + DynamoDB for state locking
- Wire modules together via outputs, not hardcoded values

### Reusable Module Pattern

```hcl
# modules/networking/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.environment}-private-${count.index}"
  }
}
```

Rules:
- Each module has its own `main.tf`, `variables.tf`, `outputs.tf`
- Modules accept configuration via variables, never hardcode values
- Use `count` or `for_each` for repeatable resources
- Tag every resource with at minimum `Name` and `Environment`

### Variable Definitions Pattern

```hcl
# variables.tf
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

Rules:
- Every variable has a `description`
- Use `type` constraints (`string`, `number`, `bool`, `list(string)`, `map(string)`, `object({...})`)
- Add `validation` blocks for constrained values
- Provide sensible `default` values where appropriate
- Never set defaults for sensitive or environment-specific values (force explicit input)

### Output Definitions Pattern

```hcl
# outputs.tf
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "database_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}
```

Rules:
- Every output has a `description`
- Mark sensitive values with `sensitive = true`
- Use splat expressions (`[*]`) for list outputs from counted resources
- Output only values that other modules or the root module need

---

## Style Limits

```yaml
limits:
  max_resource_per_file: 5        # Split into separate files if more than 5 resources
  max_file_lines: 200             # Split into modules if a file exceeds 200 lines
  max_module_resources: 10        # A module with more than 10 resources should be decomposed
  max_variable_files: 1           # One variables.tf per module
  max_nesting_depth: 2            # Avoid deeply nested dynamic blocks
```

If a file exceeds 200 lines, split resources into separate `.tf` files or extract a module. If a module exceeds 10 resources, decompose into sub-modules. If nesting exceeds 2 levels, flatten with locals or separate resources.

---

## Dependencies

```yaml
dependencies:
  manager: "tofu"
  install: "tofu init"
  add: ""                         # Providers are declared in .tf files, not installed separately
  add_dev: ""
  lock_file: ".terraform.lock.hcl"
```

---

## Project Structure

```yaml
structure:
  source_root: "."
  test_root: "tests/"
  config_files:
    - "*.tf"
    - ".terraform.lock.hcl"
  entry_point: "main.tf"
```

### Expected Directory Layout

```
project-root/
  main.tf                         # Root module entry point
  variables.tf                    # Input variables
  outputs.tf                      # Output values
  providers.tf                    # Provider configuration
  backend.tf                      # State backend config
  versions.tf                     # Required provider versions
  modules/
    {module-name}/
      main.tf                     # Module resources
      variables.tf                # Module input variables
      outputs.tf                  # Module output values
  environments/
    dev/
      terraform.tfvars            # Dev-specific variable values
    staging/
      terraform.tfvars            # Staging-specific variable values
    prod/
      terraform.tfvars            # Prod-specific variable values
  tests/
    {module}_test.tftest.hcl      # Module test files
```

---

## Pattern Files Reference

Detailed pattern files live alongside this profile for use by code-generation skills:

```
profiles/opentofu-hcl/patterns/
  module.md          # Reusable module pattern with examples
  resource.md        # Resource definition pattern with lifecycle and depends_on
  variables.md       # Variable definitions pattern with validation
  outputs.md         # Output definitions pattern
```

Commands and agents reference these patterns by path:
```
$PROFILE_DIR/patterns/module.md
$PROFILE_DIR/patterns/resource.md
```

Where `$PROFILE_DIR` resolves to `profiles/opentofu-hcl/` for this profile.

---

## Profile Metadata

```yaml
metadata:
  name: opentofu-hcl
  version: "1.0.0"
  description: "Infrastructure as Code with OpenTofu/Terraform and HCL"
  authors: ["atelier"]
  tags: ["hcl", "opentofu", "terraform", "aws", "infrastructure", "iac"]
```
