# Variables Pattern — Extended Examples

Reference examples for the variables pattern. See `../variables.md` for core rules.

## Environment-Specific Values (tfvars)

```hcl
# environments/dev/terraform.tfvars
project_name       = "myproject"
environment        = "dev"
aws_region         = "us-east-1"
vpc_cidr           = "10.0.0.0/16"
instance_type      = "t3.micro"
desired_count      = 1
enable_monitoring  = false
availability_zones = ["us-east-1a", "us-east-1b"]
```

```hcl
# environments/prod/terraform.tfvars
project_name       = "myproject"
environment        = "prod"
aws_region         = "us-east-1"
vpc_cidr           = "10.1.0.0/16"
instance_type      = "t3.large"
desired_count      = 3
enable_monitoring  = true
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
```

## Common Mistakes

```hcl
# BAD: No description
variable "vpc_cidr" {
  type = string
}

# GOOD: Description explains purpose
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

# BAD: No type (accepts anything, errors are caught late)
variable "instance_count" {
  description = "Number of instances"
}

# GOOD: Type constraint catches errors at plan time
variable "instance_count" {
  description = "Number of instances"
  type        = number
}

# BAD: Default for sensitive or environment-specific values
variable "db_password" {
  description = "Database password"
  type        = string
  default     = "changeme123"  # Insecure default
}

# GOOD: No default forces explicit input
variable "db_password" {
  description = "Master password for the RDS instance"
  type        = string
  sensitive   = true
}

# BAD: No validation for constrained values
variable "environment" {
  description = "Deployment environment"
  type        = string
  # Accepts any string including typos like "prodd"
}

# GOOD: Validation block catches invalid values
variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# BAD: Sensitive value not marked
variable "api_token" {
  description = "External service API token"
  type        = string
  # Value will appear in plan output and state
}

# GOOD: Marked sensitive
variable "api_token" {
  description = "External service API token"
  type        = string
  sensitive   = true
}
```
