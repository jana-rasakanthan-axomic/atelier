# Module Pattern

Reusable infrastructure components encapsulating related resources.

## Location

`modules/{module-name}/main.tf` - Module resources
`modules/{module-name}/variables.tf` - Module input variables
`modules/{module-name}/outputs.tf` - Module output values

## When to Use

- A group of resources is deployed together and shares a lifecycle
- The same infrastructure pattern is repeated across environments or projects
- You need to encapsulate complexity behind a simple interface (variables in, outputs out)
- A logical component (networking, compute, database) has more than 2-3 related resources

## Key Rules

1. **One concern per module** -- a module does one thing (networking, compute, storage)
2. **No hardcoded values** -- all configuration comes in through variables
3. **Expose only what is needed** -- outputs should be the minimum interface other modules require
4. **Pin provider versions in root** -- modules inherit providers from the calling module
5. **Keep modules under 10 resources** -- decompose further if larger
6. **Tag everything** -- propagate environment and project tags through variables

## Template

### Module Structure

```
modules/{module-name}/
  main.tf           # Resources
  variables.tf      # Input variables
  outputs.tf        # Output values
```

### main.tf

```hcl
# modules/networking/main.tf

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-${count.index}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-private-${count.index}"
    Tier = "private"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}
```

### variables.tf

```hcl
# modules/networking/variables.tf

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones to deploy into"
  type        = list(string)
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}
```

### outputs.tf

```hcl
# modules/networking/outputs.tf

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}
```

## Calling a Module from Root

```hcl
# main.tf (root module)
module "networking" {
  source = "./modules/networking"

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment
  project_name       = var.project_name
}

module "compute" {
  source = "./modules/compute"

  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
  # Wire modules together via outputs
}
```

## Common Mistakes

```hcl
# BAD: Hardcoded values inside a module
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"  # Hardcoded -- not reusable
}

# GOOD: Parameterized via variables
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

# BAD: Module with no outputs (other modules cannot reference it)
# modules/database/outputs.tf is empty

# GOOD: Expose what downstream modules need
output "db_endpoint" {
  description = "Database connection endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

# BAD: Giant module with 20+ resources
# modules/everything/main.tf -- 500 lines

# GOOD: Decomposed into focused modules
# modules/networking/  -- VPC, subnets, gateways
# modules/compute/     -- EC2, ASG, ALB
# modules/database/    -- RDS, parameter groups

# BAD: Provider configuration inside a module
provider "aws" {
  region = "us-east-1"  # Provider belongs in root, not in module
}

# GOOD: Module inherits provider from root (no provider block in module)
```

## Cross-References

- See `resource.md` for individual resource patterns within modules
- See `variables.md` for variable definition conventions
- See `outputs.md` for output definition conventions
