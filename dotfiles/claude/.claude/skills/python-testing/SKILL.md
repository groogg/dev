---
name: python-testing
description: Pytest conventions, fixture patterns, parametrized tests, Polyfactory for pydantic models, and mocking strategies. Use when writing or reviewing Python tests.
---

# Python Testing Skill

Pytest standards for this project. Apply these rules to all test code.

## Structure

Every test follows **Setup / Act / Assert**:

```python
def test_user_creation_assigns_default_role(db_session: Session) -> None:
    # Setup
    user_data = UserCreate(name="Alice", email="alice@example.com")

    # Act
    user = create_user(db_session, user_data)

    # Assert
    assert user.role == Role.VIEWER
    assert user.is_active is True
```

## Rules

- Fully isolated, no external state dependencies
- No test should depend on another test's output or ordering
- Test names describe the scenario: `test_<unit>_<scenario>` or `test_<unit>_<scenario>_<expected>`
- One logical assertion per test (multiple `assert` lines are fine if they verify one behavior)

## Fixtures

Use fixtures for reusable test data. Keep them close to where they're used.

```python
@pytest.fixture
def sample_user() -> User:
    return User(name="Alice", email="alice@example.com", role=Role.VIEWER)


@pytest.fixture
def authenticated_client(client: TestClient, sample_user: User) -> TestClient:
    token = create_access_token(sample_user.id)
    client.headers["Authorization"] = f"Bearer {token}"
    return client
```

- Use `tmp_path` for filesystem tests, never write to real paths
- Use `monkeypatch` for environment variables and module-level overrides

## Polyfactory

Use `polyfactory` to generate pydantic model instances in tests. Avoids manually constructing models with boilerplate field values.

```python
from polyfactory.factories.pydantic_factory import ModelFactory


class UserFactory(ModelFactory):
    __model__ = User


def test_user_serialization_roundtrip() -> None:
    user = UserFactory.build()
    serialized = user.model_dump_json()
    restored = User.model_validate_json(serialized)
    assert restored == user
```

Override specific fields when the test cares about them:

```python
def test_admin_can_delete_others() -> None:
    admin = UserFactory.build(role=Role.ADMIN)
    target = UserFactory.build(role=Role.VIEWER)
    assert can_delete(actor=admin, target=target) is True
```

Use `batch` for multiple instances:

```python
def test_list_users_returns_all(db_session: Session) -> None:
    users = UserFactory.batch(5)
    for user in users:
        db_session.add(user)
    db_session.commit()

    result = list_users(db_session)
    assert len(result) == 5
```

## Parametrized Tests

Use `@pytest.mark.parametrize` for multiple scenarios of the same behavior:

```python
@pytest.mark.parametrize(
    ("input_email", "is_valid"),
    [
        ("user@example.com", True),
        ("user@.com", False),
        ("", False),
        ("user@example.co.uk", True),
    ],
)
def test_email_validation(input_email: str, is_valid: bool) -> None:
    assert validate_email(input_email) is is_valid
```

## Mocking

- Mock at the boundary (external APIs, database, filesystem), not internal logic
- Use `unittest.mock.patch` or `monkeypatch`, prefer `monkeypatch` for simple cases
- Reusable mocks go in `conftest.py`
- Never mock the thing you're testing
