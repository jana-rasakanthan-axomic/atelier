# Cryptographic Validation

Standards for cryptographic implementations.

## Key Principles

1. **Never roll your own crypto** - Use established libraries
2. **Use strong algorithms** - AES-256, RSA-2048+, SHA-256+
3. **Secure key management** - Never hardcode, use secrets manager
4. **Regular rotation** - Keys should have expiration

## Algorithm Requirements

### Symmetric Encryption

| Use Case | Algorithm | Key Length | Mode |
|----------|-----------|------------|------|
| Data at rest | AES | 256-bit | GCM |
| Data in transit | AES | 128/256-bit | GCM |

```python
# Example: AES-256-GCM
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

def encrypt(plaintext: bytes, key: bytes) -> tuple[bytes, bytes]:
    """Encrypt data with AES-256-GCM."""
    aesgcm = AESGCM(key)
    nonce = os.urandom(12)  # 96-bit nonce
    ciphertext = aesgcm.encrypt(nonce, plaintext, None)
    return nonce, ciphertext

def decrypt(nonce: bytes, ciphertext: bytes, key: bytes) -> bytes:
    """Decrypt data with AES-256-GCM."""
    aesgcm = AESGCM(key)
    return aesgcm.decrypt(nonce, ciphertext, None)
```

### Asymmetric Encryption

| Use Case | Algorithm | Key Length |
|----------|-----------|------------|
| Key exchange | RSA | 2048+ bits |
| Digital signatures | RSA/ECDSA | 2048+/256+ bits |
| TLS | ECDHE | 256+ bits |

### Hashing

| Use Case | Algorithm | Notes |
|----------|-----------|-------|
| Passwords | Argon2id, bcrypt | With salt |
| Data integrity | SHA-256 | Not for passwords |
| HMAC | HMAC-SHA256 | For message auth |

```python
# Example: Password hashing with Argon2
from argon2 import PasswordHasher

ph = PasswordHasher(
    time_cost=3,
    memory_cost=65536,
    parallelism=4,
)

def hash_password(password: str) -> str:
    """Hash password with Argon2id."""
    return ph.hash(password)

def verify_password(password: str, hash: str) -> bool:
    """Verify password against hash."""
    try:
        ph.verify(hash, password)
        return True
    except Exception:
        return False
```

## Key Derivation

For deriving keys from passwords:

| Algorithm | Iterations | Salt Length |
|-----------|------------|-------------|
| PBKDF2-SHA256 | 100,000+ | 16+ bytes |
| Argon2id | time=3, mem=64MB | 16+ bytes |

```python
# Example: PBKDF2 key derivation
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

def derive_key(password: str, salt: bytes) -> bytes:
    """Derive encryption key from password."""
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,  # 256-bit key
        salt=salt,
        iterations=100_000,
    )
    return kdf.derive(password.encode())
```

## Secrets Management

### DO

```python
# Load from environment
import os
SECRET_KEY = os.environ["SECRET_KEY"]

# Use secrets manager
from aws_secretsmanager import get_secret
SECRET_KEY = get_secret("app/secret-key")
```

### DON'T

```python
# NEVER hardcode secrets
SECRET_KEY = "my-secret-key-123"  # BAD

# NEVER commit secrets
# .env files should be gitignored
```

## Validation Checklist

### Algorithm Strength

- [ ] AES key length >= 256 bits
- [ ] RSA key length >= 2048 bits
- [ ] ECDSA curve >= P-256
- [ ] No MD5, SHA-1, DES, 3DES
- [ ] No ECB mode

### Implementation

- [ ] Using established library (cryptography, PyNaCl)
- [ ] Random IV/nonce for each encryption
- [ ] Salt for password hashing
- [ ] Constant-time comparison for secrets

### Key Management

- [ ] Keys loaded from secrets manager
- [ ] No hardcoded secrets
- [ ] Key rotation policy defined
- [ ] Separate keys per environment

### Transport Security

- [ ] TLS 1.2+ required
- [ ] Strong cipher suites
- [ ] Certificate validation
- [ ] HSTS enabled

## Common Vulnerabilities

### Weak Random Generation

```python
# BAD: Predictable
import random
token = str(random.randint(0, 999999))

# GOOD: Cryptographically secure
import secrets
token = secrets.token_urlsafe(32)
```

### Timing Attacks

```python
# BAD: Early exit leaks timing info
def verify(input: str, expected: str) -> bool:
    if len(input) != len(expected):
        return False
    for i in range(len(input)):
        if input[i] != expected[i]:
            return False
    return True

# GOOD: Constant-time comparison
import hmac
def verify(input: str, expected: str) -> bool:
    return hmac.compare_digest(input, expected)
```

### IV/Nonce Reuse

```python
# BAD: Fixed nonce
nonce = b"fixed-nonce"

# GOOD: Random nonce per encryption
nonce = os.urandom(12)
```

## Audit Requirements

For high-security features:

1. **Internal review** - Security team sign-off
2. **External audit** - Third-party cryptographic audit
3. **Documentation** - Threat model, key management procedures
4. **Testing** - Known-answer tests, fuzzing
