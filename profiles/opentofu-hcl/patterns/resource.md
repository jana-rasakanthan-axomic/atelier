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

### Resource with depends_on

```hcl
resource "aws_ecs_service" "api" {
  name            = "${var.project_name}-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.desired_count

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 8000
  }

  # ALB listener rule must exist before the service can register targets
  depends_on = [aws_lb_listener_rule.api]
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

```hcl
# BAD: Generic resource name
resource "aws_instance" "instance1" { ... }

# GOOD: Descriptive resource name
resource "aws_instance" "api_server" { ... }

# BAD: Using count for a map of distinct items (reordering breaks state)
resource "aws_subnet" "private" {
  count = length(var.subnet_configs)
  cidr_block = var.subnet_configs[count.index].cidr
}

# GOOD: Using for_each for distinct items (stable keys)
resource "aws_subnet" "private" {
  for_each          = { for s in var.subnet_configs : s.name => s }
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
}

# BAD: depends_on when implicit dependency exists
resource "aws_instance" "web" {
  subnet_id  = aws_subnet.main.id        # Implicit dependency already exists
  depends_on = [aws_subnet.main]          # Redundant
}

# GOOD: Let implicit dependencies work
resource "aws_instance" "web" {
  subnet_id = aws_subnet.main.id          # Tofu infers the dependency
}

# BAD: Unencrypted storage
resource "aws_ebs_volume" "data" {
  size = 100
}

# GOOD: Encrypted by default
resource "aws_ebs_volume" "data" {
  size      = 100
  encrypted = true
}

# BAD: No tags
resource "aws_instance" "web" {
  ami           = "ami-12345"
  instance_type = "t3.micro"
}

# GOOD: Tagged with Name and Environment at minimum
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type

  tags = {
    Name        = "${var.project_name}-${var.environment}-web"
    Environment = var.environment
  }
}
```

## Cross-References

- See `module.md` for grouping resources into reusable modules
- See `variables.md` for parameterizing resource configurations
- See `outputs.md` for exposing resource attributes to other modules
