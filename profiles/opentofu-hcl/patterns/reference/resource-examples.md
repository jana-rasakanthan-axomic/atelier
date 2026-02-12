# Resource Pattern — Extended Examples

Reference examples for the resource pattern. See `../resource.md` for core rules.

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
