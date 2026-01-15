---
name: error-handler
description: Implements robust error handling with custom errors, boundaries, and API responses.
---

# Error Handling Patterns

## TypeScript Custom Errors

```typescript
class AppError extends Error {
  constructor(
    message: string,
    public code: string,
    public statusCode: number = 500,
    public isOperational: boolean = true
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

class ValidationError extends AppError {
  constructor(message: string) { super(message, 'VALIDATION_ERROR', 400); }
}

class NotFoundError extends AppError {
  constructor(resource: string) { super(`${resource} not found`, 'NOT_FOUND', 404); }
}

class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized') { super(message, 'UNAUTHORIZED', 401); }
}

class ForbiddenError extends AppError {
  constructor(message = 'Forbidden') { super(message, 'FORBIDDEN', 403); }
}
```

## Express Error Handling

```typescript
// Async wrapper
const asyncHandler = (fn: Function) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

// Global error handler
const errorHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || 500;
  if (!err.isOperational) console.error('Unexpected error:', err);

  res.status(statusCode).json({
    error: {
      code: err.code || 'INTERNAL_ERROR',
      message: err.message,
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    }
  });
};
```

## React Error Boundary

```typescript
class ErrorBoundary extends Component<
  { children: ReactNode; fallback?: ReactNode; onError?: (error: Error) => void },
  { hasError: boolean; error: Error | null }
> {
  state = { hasError: false, error: null };

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    this.props.onError?.(error);
  }

  render() {
    if (this.state.hasError) return this.props.fallback || <DefaultErrorFallback />;
    return this.props.children;
  }
}
```

## Python Custom Exceptions

```python
class AppError(Exception):
    def __init__(self, message: str, code: str, status_code: int = 500, details: dict = None):
        self.message, self.code, self.status_code = message, code, status_code
        self.details = details or {}
        super().__init__(message)

    def to_dict(self):
        return {"error": {"code": self.code, "message": self.message, "details": self.details}}

class ValidationError(AppError):
    def __init__(self, message: str, details: dict = None):
        super().__init__(message, "VALIDATION_ERROR", 400, details)

class NotFoundError(AppError):
    def __init__(self, resource: str):
        super().__init__(f"{resource} not found", "NOT_FOUND", 404)
```

## FastAPI Error Handling

```python
@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError):
    return JSONResponse(status_code=exc.status_code, content=exc.to_dict())

@app.exception_handler(Exception)
async def generic_error_handler(request: Request, exc: Exception):
    logger.exception("Unexpected error")
    return JSONResponse(status_code=500, content={"error": {"code": "INTERNAL_ERROR", "message": "Internal server error"}})
```

## API Error Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is required",
    "details": [{ "field": "email", "message": "Required" }]
  }
}
```

## Best Practices

1. Use specific error types for domain errors
2. Include error codes for programmatic handling
3. Log all errors server-side; show actionable messages client-side
4. Never expose stack traces in production
