# Resource Pattern

Individual cloud resource definitions with lifecycle management and dependency handling.

## Location

`modules/{module-name}/main.tf` - Resources within a module
`main.tf` - Resources in the root module (rare; prefer modules)

## When to Use

- Defining any cloud infrastructure component (EC2, S3, RDS, IAM, etc.)
- A resource needs explicit lifecycle rules (prevent destroy, create before destroy)
- Resources have ordering dependencies that cannot be inferred automatically
- You need conditional resource creation based on feature flags

## Key Rules

1. **One resource type per logical name** -- `aws_instance.web_server` not `aws_instance.instance1`
2. **Descriptive resource names** -- the name after the dot should describe the purpose, not the type
3. **Use `depends_on` sparingly** -- only when implicit dependency through references is insufficient
4. **Always tag resources** -- at minimum `Name` and `Environment`
5. **Use `lifecycle` blocks intentionally** -- document why each lifecycle rule exists
6. **Prefer `for_each` over `count`** -- `for_each` is safer for additions/removals in the middle of a set

## Template

### Basic Resource

```hcl
resource "aws_instance" "api_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [aws_security_group.api.id]

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-api"
    Role = "api-server"
  }
}
```

### Resource with Lifecycle Rules

```hcl
resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-${var.environment}"
  engine         = "postgres"
  engine_version = var.postgres_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_storage_gb
  max_allocated_storage = var.db_max_storage_gb
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = var.environment == "prod" ? 30 : 7
  skip_final_snapshot     = var.environment != "prod"
  deletion_protection     = var.environment == "prod"

  lifecycle {
    # Prevent accidental destruction of production databases
    prevent_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-db"
  }
}
```

### Resource with for_each

```hcl
resource "aws_s3_bucket" "assets" {
  for_each = toset(var.bucket_names)

  bucket = "${var.project_name}-${var.environment}-${each.value}"

  tags = {
    Name    = each.value
    Purpose = each.value
  }
}

resource "aws_s3_bucket_versioning" "assets" {
  for_each = aws_s3_bucket.assets

  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

### Conditional Resource with count

```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  alarm_actions = [var.sns_topic_arn]

  dimensions = {
    InstanceId = aws_instance.api_server.id
  }
}
```

### Data Source

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

## Lifecycle Block Reference

| Rule | When to Use |
|------|-------------|
| `prevent_destroy = true` | Production databases, state buckets, encryption keys |
| `create_before_destroy = true` | Zero-downtime replacements (security groups, launch configs) |
| `ignore_changes = [...]` | Fields managed outside Tofu (auto-scaling desired count, external tags) |
| `replace_triggered_by = [...]` | Force replacement when a dependency changes |

## Common Mistakes

Key mistakes to avoid:
- Generic resource names (`instance1` instead of `api_server`)
- Using `count` for distinct items (reordering breaks state) -- use `for_each` instead
- Redundant `depends_on` when implicit dependency through references already exists
- Unencrypted storage volumes
- Missing tags on resources

See `reference/resource-examples.md` for detailed common mistake examples.

## Cross-References

- See `module.md` for grouping resources into reusable modules
- See `variables.md` for parameterizing resource configurations
- See `outputs.md` for exposing resource attributes to other modules
