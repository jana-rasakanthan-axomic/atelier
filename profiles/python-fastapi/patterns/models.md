# Models Pattern

SQLAlchemy ORM models with mixins for common fields.

## Location

- `src/db/models/base.py` - Base class and mixins
- `src/db/models/{domain}.py` - Domain entities

## Key Rules

1. **Use mixins** - `IdMixin`, `TimeStampedMixin` for common fields
2. **UUID7 primary keys** - sortable by creation time
3. **server_default** - database-side timestamps, not Python-side

## Mixins

```python
class IdMixin:
    id: Mapped[uuid.UUID] = mapped_column(
        PG_UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid7,
    )

class TimeStampedMixin:
    created_at: Mapped[datetime.datetime] = mapped_column(
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime.datetime] = mapped_column(
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
```

## Entity Example

```python
class {Entity}(Base, IdMixin, TimeStampedMixin):
    __tablename__ = "{entities}"

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    email: Mapped[str] = mapped_column(String(255), nullable=False, unique=True)
    status: Mapped[str] = mapped_column(String(50), default="active")
```

## Anti-Patterns

```python
# BAD: Python-side timestamp
created_at = mapped_column(default=datetime.datetime.utcnow)

# GOOD: Database-side
created_at = mapped_column(server_default=func.now())

# BAD: uuid4 (random)
default=uuid.uuid4

# GOOD: UUID7 (time-ordered)
default=uuid.uuid7

# BAD: Repeating fields
class Entity1(Base):
    id = mapped_column(...)
    created_at = mapped_column(...)

# GOOD: Mixins
class Entity1(Base, IdMixin, TimeStampedMixin): ...
```

## Pydantic vs Dataclass for DTOs

**Default: Use Pydantic for all DTOs and data models.**

Pydantic provides validation, serialization, and better error messages. Use it unless you have a specific reason not to.

### When to Use Pydantic (Default)

**Request/Response DTOs** (API models):
```python
class CreateUserRequest(BaseModel):
    name: str
    email: EmailStr
    age: int = Field(ge=18)
```

**Domain Models** (if not using SQLAlchemy):
```python
class User(BaseModel):
    id: UUID
    name: str
    email: EmailStr
    created_at: datetime
```

**Configuration Models**:
```python
class DatabaseConfig(BaseModel):
    host: str
    port: int = 5432
    database: str
```

### When to Use Dataclass (Rare)

Use `@dataclass` ONLY for:

**Internal data structures** where validation overhead is unnecessary:
```python
@dataclass
class InternalCacheEntry:
    key: str
    value: Any
    expires_at: float
```

**Performance-critical paths** (after profiling shows Pydantic is bottleneck):
```python
@dataclass
class LogEntry:
    timestamp: float
    level: str
    message: str
```

**Simple grouping** of related values (no validation needed):
```python
@dataclass
class Point:
    x: float
    y: float
```

### Decision Tree

```
Need a data model?
  ├─ Is it an API input/output? → Pydantic
  ├─ Does it need validation? → Pydantic
  ├─ Does it serialize to JSON? → Pydantic
  ├─ Is it a configuration? → Pydantic
  ├─ Is it a domain entity? → Pydantic (or SQLAlchemy if persisted)
  └─ Is it a simple internal struct with no validation? → Consider dataclass
```

### Anti-Pattern: Using Dataclass for DTOs

```python
# WRONG - Dataclass for API model (missing validation!)
@dataclass
class CreateUserRequest:
    name: str
    email: str       # Won't validate email format
    age: int         # Won't validate age >= 18

# CORRECT - Pydantic for API model
class CreateUserRequest(BaseModel):
    name: str
    email: EmailStr  # Validates email format
    age: int = Field(ge=18)  # Validates age >= 18
```

**Summary:** Default to Pydantic for everything. Use dataclass only for internal-only data structures where validation is unnecessary.

## Cross-References

- See `repository.md` for data access
- See `_shared.md` for three-model strategy
- See `router.md` for DTO usage in routes
