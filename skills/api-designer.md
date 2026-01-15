# API Designer

Expert API architect for RESTful and GraphQL API design.

## REST API Design

**Endpoints:** Resource-based URLs, proper HTTP methods, plural nouns, kebab-case

**Request/Response:** Consistent envelope, proper status codes, pagination, filtering/sorting

**Best Practices:** HATEOAS links, idempotency keys, rate limiting headers, versioning

## GraphQL Schema Design

**Structure:** Types, Queries, Mutations, Subscriptions, Inputs

**Best Practices:** Relay-style pagination, proper nullability, interfaces/unions, custom scalars

## Authentication

**Patterns:** JWT, OAuth 2.0, API keys, sessions

**Security:** Token expiration, refresh rotation, scope-based permissions, rate limiting

## Output Formats

### OpenAPI 3.0
```yaml
openapi: 3.0.3
info:
  title: API Name
  version: 1.0.0
paths:
  /resource:
    get:
      summary: List resources
      responses:
        '200':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ResourceList'
```

### GraphQL SDL
```graphql
type Query {
  user(id: ID!): User
  users(first: Int, after: String): UserConnection!
}

type Mutation {
  createUser(input: CreateUserInput!): CreateUserPayload!
}

type User {
  id: ID!
  email: String!
  posts(first: Int, after: String): PostConnection!
}
```

### TypeScript
```typescript
interface User {
  id: string;
  email: string;
  name: string | null;
}

interface ApiResponse<T> {
  data: T;
  meta?: { page: number; perPage: number; total: number };
}

interface ApiError {
  error: { code: string; message: string; details?: Record<string, string[]> };
}
```

## Common Patterns

### Pagination
```json
{
  "data": [...],
  "meta": { "page": 1, "per_page": 20, "total": 100 },
  "links": { "self": "/users?page=1", "next": "/users?page=2" }
}
```

### Error Response
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid data",
    "details": { "email": ["must be valid email"] }
  }
}
```

### Versioning
- URL: `/v1/users`
- Header: `Accept: application/vnd.api+json; version=1`
- Query: `/users?version=1`

## Design Workflow

1. **Requirements** - Resources, operations, consumers, performance needs
2. **Resource Modeling** - Core resources, relationships, attributes
3. **Endpoint Design** - Map resources, define schemas, document errors
4. **Security** - Auth mechanism, authorization model, rate limiting
5. **Documentation** - OpenAPI spec, examples, error codes
