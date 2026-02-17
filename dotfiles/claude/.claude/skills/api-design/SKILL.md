---
name: api-design
description: REST API design best practices, versioning strategies, error handling, pagination, and OpenAPI documentation. Use when designing or implementing REST APIs, HTTP endpoints, or API documentation.
---

# API Design Skill

REST API design best practices, HTTP conventions, versioning, error handling, and documentation standards.

## Core Concepts

### REST Principles

RESTful resource design using nouns (not verbs), proper HTTP methods, and hierarchical URL structure.

**Key Principles**:
- Resources are nouns: `/users`, `/posts` (not `/getUsers`, `/createPost`)
- Use HTTP methods correctly: GET (read), POST (create), PUT (replace), PATCH (update), DELETE (remove)
- Hierarchical relationships: `/users/123/posts` for related resources
- Keep URLs shallow (max 3 levels)

**See**: `docs/rest-principles.md` for detailed examples and patterns

---

### HTTP Status Codes

Proper status code usage for success (2xx), client errors (4xx), and server errors (5xx).

**Common Codes**:
- **200 OK**: Successful GET/PUT/PATCH
- **201 Created**: Successful POST (includes Location header)
- **202 Accepted**: Request accepted for async processing
- **204 No Content**: Successful DELETE
- **400 Bad Request**: Invalid input
- **401 Unauthorized**: Authentication required
- **403 Forbidden**: Authenticated but not allowed
- **404 Not Found**: Resource doesn't exist
- **422 Unprocessable**: Validation error
- **429 Too Many Requests**: Rate limit exceeded
- **500 Internal Server Error**: Server failure

**See**: `docs/http-status-codes.md` for complete reference and examples

---

### Error Handling

RFC 7807 Problem Details format for consistent, structured error responses.

**Standard Format**:
```json
{
  "type": "https://example.com/errors/validation-error",
  "title": "Validation Error",
  "status": 422,
  "detail": "Email address is invalid",
  "instance": "/users",
  "errors": {
    "email": ["Must be a valid email address"]
  }
}
```

**See**: `docs/error-handling.md` for implementation patterns and best practices

---

### Request/Response Format

JSON structure conventions for request bodies and response payloads.

**Best Practices**:
- Define all request and response schemas as Pydantic models
- Use `snake_case` for JSON keys
- Include metadata in responses (timestamps, IDs)
- Consistent field naming across endpoints
- Clear data types and structures

**See**: `docs/request-response-format.md` for detailed examples

---

### Pagination

Offset-based and cursor-based pagination strategies for large datasets.

**Offset-Based** (simple, good for small datasets):
```bash
GET /users?page=2&limit=20
```

**Cursor-Based** (scalable, handles real-time updates):
```bash
GET /users?cursor=abc123&limit=20
```

**See**: `docs/pagination.md` for implementation details and trade-offs

---

### API Versioning

URL path versioning (recommended) and header-based versioning strategies.

**URL Path Versioning**:
```bash
/v1/users
/v2/users
```

**When to Version**:
- Breaking changes (removing fields, changing behavior)
- New required fields
- Changed data types

**See**: `docs/versioning.md` for migration strategies and deprecation policies

---

### Authentication & Authorization

API key and JWT authentication patterns for securing endpoints.

**API Key** (simple, good for service-to-service):
```http
Authorization: Bearer sk_live_abc123...
```

**JWT** (stateless, good for user authentication):
```http
Authorization: Bearer eyJhbGc...
```

**See**: `docs/authentication.md` for implementation patterns

---

### Advanced Features

CORS configuration, filtering, sorting, and search patterns.

**Topics**:
- CORS headers for browser-based clients
- Query parameter filtering
- Multi-field sorting
- Full-text search

**See**: `docs/advanced-features.md` for detailed patterns

---

### Documentation

OpenAPI/Swagger documentation for API discoverability.

**Auto-Generated** (FastAPI):
```python
@app.get("/users/{user_id}", response_model=User)
def get_user(user_id: int) -> User:
    return db.get_user(user_id)
```

**See**: `docs/documentation.md` for OpenAPI specifications

---

### Design Patterns

Idempotency, content negotiation, HATEOAS, bulk operations, and webhooks.

**Topics**:
- Idempotency keys for safe retries
- Content negotiation (JSON, XML, etc.)
- HATEOAS for discoverable APIs
- Bulk operations for batch processing
- Webhooks for event notifications

**See**: `docs/idempotency-content-negotiation.md` and `docs/patterns-checklist.md`

---

## API Design Checklist

**Before Launch**:
- [ ] Use RESTful resource naming (nouns, not verbs)
- [ ] Implement proper HTTP status codes
- [ ] Add RFC 7807 error responses
- [ ] Include pagination for collections
- [ ] Add API versioning strategy
- [ ] Implement authentication
- [ ] Configure CORS (if browser clients)
- [ ] Generate OpenAPI documentation
- [ ] Test idempotency for POST/PUT/DELETE

---

## Key Takeaways

- **Resources are nouns**: `/users`, not `/getUsers`
- **Use HTTP methods correctly**: GET (read), POST (create), PUT (replace), DELETE (remove)
- **Return proper status codes**: 200 (success), 201 (created), 404 (not found), 422 (validation error)
- **Structured errors**: Use RFC 7807 format
- **Paginate collections**: Offset or cursor-based
- **Version your API**: URL path versioning (e.g., `/v1/users`)
- **Secure endpoints**: API keys or JWT
- **Document thoroughly**: OpenAPI/Swagger
- **Test idempotency**: Safe retries for POST/PUT/DELETE
