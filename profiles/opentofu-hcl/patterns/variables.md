# Variables Pattern

Input variable definitions with type constraints and validation.

## Location

`variables.tf` - Root module variables
`modules/{module-name}/variables.tf` - Module-specific variables
`environments/{env}/terraform.tfvars` - Environment-specific values

## When to Use

- Any value that differs between environments (dev/staging/prod)
- Any value that a module consumer should be able to configure
- Any value that should not be hardcoded (CIDR blocks, instance types, counts)
- Sensitive values like passwords or API keys (mark with `sensitive = true`)

## Key Rules

1. **Every variable has a `description`** -- no exceptions, even for obvious ones
2. **Always specify `type`** -- enables early validation and clear documentation
3. **Add `validation` blocks for constrained values** -- catch errors before plan/apply
4. **Use `default` only for genuinely optional values** -- force explicit input for environment-specific or sensitive values
5. **Group related variables together** -- networking variables near each other, compute variables near each other
6. **One `variables.tf` per module** -- all variables in a single file for discoverability
7. **Mark sensitive variables** -- `sensitive = true` for passwords, tokens, keys

## Template

### Simple Variables

```hcl
variable "project_name" {
  description = "Name of the project, used in resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}
```

### Variables with Type Constraints

```hcl
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of AWS availability zones to deploy into"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required for high availability."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the application servers"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^t[23]\\.", var.instance_type))
    error_message = "Only t2 and t3 instance types are allowed."
  }
}

variable "desired_count" {
  description = "Desired number of running instances"
  type        = number
  default     = 2

  validation {
    condition     = var.desired_count >= 1 && var.desired_count <= 10
    error_message = "Desired count must be between 1 and 10."
  }
}
```

### Complex Type Variables

```hcl
variable "subnet_configs" {
  description = "Configuration for each subnet"
  type = list(object({
    name = string
    cidr = string
    az   = string
    tier = string
  }))

  validation {
    condition     = alltrue([for s in var.subnet_configs : contains(["public", "private"], s.tier)])
    error_message = "Subnet tier must be 'public' or 'private'."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_monitoring" {
  description = "Whether to create CloudWatch alarms and dashboards"
  type        = bool
  default     = false
}
```

### Sensitive Variables

```hcl
variable "db_password" {
  description = "Master password for the RDS instance"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 16
    error_message = "Database password must be at least 16 characters."
  }
}

variable "api_key" {
  description = "API key for the external monitoring service"
  type        = string
  sensitive   = true
}
```

## Environment-Specific Values

Define per-environment values in `terraform.tfvars` files. See `reference/variables-examples.md` for dev and prod tfvars examples.

## Type Reference

| Type | Example | Use Case |
|------|---------|----------|
| `string` | `"us-east-1"` | Single text values |
| `number` | `3` | Counts, sizes, ports |
| `bool` | `true` | Feature flags |
| `list(string)` | `["a", "b"]` | Ordered collections |
| `set(string)` | `["a", "b"]` | Unique unordered collections |
| `map(string)` | `{key = "val"}` | Key-value pairs |
| `object({...})` | `{name = string, port = number}` | Structured configuration |
| `tuple([...])` | `[string, number]` | Fixed-length mixed-type lists |

## Common Mistakes

Key mistakes to avoid:
- Missing `description` on variables
- Omitting `type` constraint (errors caught late)
- Providing `default` for sensitive or environment-specific values
- Missing `validation` blocks for constrained values (typos like "prodd" accepted)
- Not marking sensitive values with `sensitive = true`

See `reference/variables-examples.md` for detailed common mistake examples.

## Cross-References

- See `module.md` for how modules consume variables
- See `outputs.md` for exposing computed values
- See `resource.md` for using variables in resource definitions
