# Outputs Pattern

Output value definitions for exposing resource attributes to callers and other modules.

## Location

`outputs.tf` - Root module outputs (exposed to CLI and remote state consumers)
`modules/{module-name}/outputs.tf` - Module outputs (exposed to the calling module)

## When to Use

- A module creates resources that other modules need to reference (VPC ID, subnet IDs)
- The root module needs to display values after `tofu apply` (endpoint URLs, ARNs)
- Values need to be consumed by other Tofu configurations via `terraform_remote_state`
- Sensitive infrastructure details need to be passed between modules without logging

## Key Rules

1. **Every output has a `description`** -- explains what the value represents and who consumes it
2. **Mark sensitive outputs** -- `sensitive = true` for endpoints, passwords, connection strings
3. **Output only what is needed** -- do not expose internal implementation details
4. **Use splat expressions for lists** -- `resource.name[*].attribute` for counted/for_each resources
5. **Output IDs and ARNs, not full objects** -- keep the interface minimal and stable
6. **Name outputs for the consumer** -- `vpc_id` not `the_vpc_id_value`, `db_endpoint` not `rds_output`

## Template

### Module Outputs

```hcl
# modules/networking/outputs.tf

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ip" {
  description = "Elastic IP of the NAT gateway"
  value       = aws_eip.nat.public_ip
}
```

### Root Module Outputs

```hcl
# outputs.tf (root module)

output "api_endpoint" {
  description = "Public URL of the API load balancer"
  value       = "https://${aws_lb.api.dns_name}"
}

output "database_endpoint" {
  description = "RDS connection endpoint (host:port)"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "ecr_repository_url" {
  description = "ECR repository URL for pushing container images"
  value       = aws_ecr_repository.api.repository_url
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  value       = aws_cloudfront_distribution.main.id
}
```

### Outputs from for_each Resources

```hcl
output "bucket_arns" {
  description = "Map of bucket name to ARN"
  value       = { for k, v in aws_s3_bucket.assets : k => v.arn }
}

output "bucket_names" {
  description = "Map of logical name to actual bucket name"
  value       = { for k, v in aws_s3_bucket.assets : k => v.id }
}
```

### Conditional Outputs

```hcl
output "monitoring_dashboard_url" {
  description = "CloudWatch dashboard URL (only available when monitoring is enabled)"
  value       = var.enable_monitoring ? aws_cloudwatch_dashboard.main[0].dashboard_arn : null
}
```

### Sensitive Outputs

```hcl
output "db_connection_string" {
  description = "Full database connection string for application configuration"
  value       = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.main.endpoint}/${var.db_name}"
  sensitive   = true
}

output "redis_auth_token" {
  description = "Redis AUTH token for ElastiCache connection"
  value       = aws_elasticache_replication_group.main.auth_token
  sensitive   = true
}
```

### Consuming Outputs from Remote State

```hcl
# In a separate Tofu configuration that needs networking outputs
data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = "myproject-terraform-state"
    key    = "networking/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_instance" "api" {
  subnet_id = data.terraform_remote_state.networking.outputs.private_subnet_ids[0]
}
```

## Output Naming Conventions

| Pattern | Example | When to Use |
|---------|---------|-------------|
| `{resource}_id` | `vpc_id`, `cluster_id` | Single resource identifier |
| `{resource}_arn` | `role_arn`, `bucket_arn` | When ARN is needed for IAM or cross-account |
| `{resource}_ids` | `subnet_ids`, `sg_ids` | List of identifiers |
| `{resource}_endpoint` | `db_endpoint`, `api_endpoint` | Connection endpoints |
| `{resource}_name` | `bucket_name`, `cluster_name` | Human-readable names |
| `{resource}_url` | `repository_url`, `dashboard_url` | Full URLs |

## Common Mistakes

```hcl
# BAD: No description
output "vpc_id" {
  value = aws_vpc.main.id
}

# GOOD: Description explains purpose
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

# BAD: Exposing sensitive values without marking them
output "db_password" {
  description = "Database password"
  value       = var.db_password
  # Will appear in CLI output and state
}

# GOOD: Marked as sensitive
output "db_password" {
  description = "Database master password"
  value       = var.db_password
  sensitive   = true
}

# BAD: Outputting entire resource objects (unstable interface)
output "vpc" {
  description = "The entire VPC object"
  value       = aws_vpc.main
}

# GOOD: Output specific attributes
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# BAD: Redundant or noisy output names
output "the_main_vpc_identifier_value" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

# GOOD: Concise, predictable names
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

# BAD: Not using splat for counted resources
output "subnet_ids" {
  value = [
    aws_subnet.private[0].id,
    aws_subnet.private[1].id,
    aws_subnet.private[2].id,
  ]
}

# GOOD: Splat expression handles any count
output "subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}
```

## Cross-References

- See `module.md` for how modules expose outputs to callers
- See `variables.md` for input variables that pair with outputs
- See `resource.md` for the resources whose attributes become outputs
