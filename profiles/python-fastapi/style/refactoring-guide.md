# Refactoring Guide: Style Limits

Detailed before/after examples for refactoring code that exceeds style limits.

## Function Length Refactoring

### Before: Monolithic function (>50 lines)

```python
def process_order(self, dto: CreateOrderDTO) -> Order:
    # Validation (10 lines)
    if not dto.items:
        raise ValidationError("No items")
    if dto.total < 0:
        raise ValidationError("Negative total")
    # ... more validation

    # User lookup (5 lines)
    user = self.user_repository.get(dto.user_id)
    if not user:
        raise UserNotFoundError(dto.user_id)

    # Inventory check (10 lines)
    for item in dto.items:
        stock = self.inventory.get(item.product_id)
        if stock < item.quantity:
            raise InsufficientStockError(item.product_id)

    # Payment processing (15 lines)
    payment = self.payment_gateway.charge(...)
    # ... payment logic

    # Order creation (10 lines)
    order = Order(...)
    # ... order logic

    return order  # Total: 50+ lines
```

### After: Extracted helpers (each <15 lines)

```python
def process_order(self, dto: CreateOrderDTO) -> Order:
    self._validate_order(dto)
    self._ensure_inventory(dto.items)
    payment = self._process_payment(dto)
    return self._create_order(dto, payment)

def _validate_order(self, dto: CreateOrderDTO) -> None:
    if not dto.items:
        raise ValidationError("No items")
    if dto.total < 0:
        raise ValidationError("Negative total")
    # ... other validation

def _ensure_inventory(self, items: list[OrderItem]) -> None:
    for item in items:
        stock = self.inventory.get(item.product_id)
        if stock < item.quantity:
            raise InsufficientStockError(item.product_id)

def _process_payment(self, dto: CreateOrderDTO) -> Payment:
    return self.payment_gateway.charge(
        amount=dto.total,
        currency=dto.currency,
        user_id=dto.user_id,
    )
```

## Class Length Refactoring

### Before: God class (>400 lines)

```python
# UserService handles users, auth, notifications, and analytics
class UserService:
    def create_user(self, ...): ...    # User CRUD
    def get_user(self, ...): ...
    def update_user(self, ...): ...
    def delete_user(self, ...): ...
    def authenticate(self, ...): ...   # Auth
    def verify_token(self, ...): ...
    def send_welcome(self, ...): ...   # Notifications
    def send_reset(self, ...): ...
    def track_login(self, ...): ...    # Analytics
    def generate_report(self, ...): ...
```

### After: Focused classes

```python
class UserService:           # User CRUD only
class AuthService:           # Authentication/authorization
class NotificationService:   # User notifications
class UserAnalyticsService:  # User metrics
```

## Cyclomatic Complexity Refactoring

### Before: High complexity (12)

```python
def calculate_discount(user, order, promo_code):
    if user.is_premium:
        if order.total > 100:
            discount = 0.20
        elif order.total > 50:
            discount = 0.15
        else:
            discount = 0.10
    elif promo_code:
        if promo_code == "SAVE20":
            discount = 0.20
        elif promo_code == "SAVE10":
            discount = 0.10
        else:
            discount = 0.05
    elif order.total > 200:
        discount = 0.10
    elif order.total > 100:
        discount = 0.05
    else:
        discount = 0.0

    if user.first_order:
        discount += 0.05
    if order.has_subscription:
        discount += 0.05

    return min(discount, 0.50)
```

### After: Extracted logic (complexity 3 per function)

```python
def calculate_discount(user, order, promo_code):
    base_discount = self._get_base_discount(user, order, promo_code)
    bonus_discount = self._get_bonus_discount(user, order)
    return min(base_discount + bonus_discount, 0.50)

def _get_base_discount(user, order, promo_code):
    if user.is_premium:
        return self._premium_discount(order.total)
    if promo_code:
        return self._promo_discount(promo_code)
    return self._order_total_discount(order.total)
```
