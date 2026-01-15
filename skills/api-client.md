---
name: api-client
description: Creates type-safe API clients with error handling, retries, and authentication.
---

# API Client Patterns

## TypeScript Fetch Wrapper

```typescript
class ApiError extends Error {
  constructor(
    message: string,
    public code: string,
    public status: number,
    public details?: unknown
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

class ApiClient {
  constructor(private config: {
    baseUrl: string;
    headers?: Record<string, string>;
    timeout?: number;
    onUnauthorized?: () => void;
  }) {}

  private async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.config.timeout ?? 10000);

    try {
      const response = await fetch(`${this.config.baseUrl}${endpoint}`, {
        ...options,
        headers: { 'Content-Type': 'application/json', ...this.config.headers, ...options.headers },
        signal: controller.signal,
      });

      if (response.status === 401) this.config.onUnauthorized?.();

      if (!response.ok) {
        const body = await response.json().catch(() => ({}));
        throw new ApiError(
          body.error?.message || 'Request failed',
          body.error?.code || 'UNKNOWN_ERROR',
          response.status,
          body.error?.details
        );
      }

      return response.status === 204 ? undefined as T : response.json();
    } catch (error) {
      if (error instanceof ApiError) throw error;
      if (error.name === 'AbortError') throw new ApiError('Request timeout', 'TIMEOUT', 408);
      throw new ApiError('Network error', 'NETWORK_ERROR', 0);
    } finally {
      clearTimeout(timeout);
    }
  }

  get<T>(endpoint: string, params?: Record<string, string>) {
    const url = params ? `${endpoint}?${new URLSearchParams(params)}` : endpoint;
    return this.request<T>(url, { method: 'GET' });
  }

  post<T>(endpoint: string, data?: unknown) {
    return this.request<T>(endpoint, { method: 'POST', body: data ? JSON.stringify(data) : undefined });
  }

  put<T>(endpoint: string, data: unknown) {
    return this.request<T>(endpoint, { method: 'PUT', body: JSON.stringify(data) });
  }

  patch<T>(endpoint: string, data: unknown) {
    return this.request<T>(endpoint, { method: 'PATCH', body: JSON.stringify(data) });
  }

  delete<T>(endpoint: string) {
    return this.request<T>(endpoint, { method: 'DELETE' });
  }
}
```

## Retry with Exponential Backoff

```typescript
async function withRetry<T>(
  fn: () => Promise<T>,
  { maxRetries = 3, baseDelay = 1000, maxDelay = 30000 } = {}
): Promise<T> {
  let lastError: Error;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;
      if (attempt === maxRetries) break;
      if (error instanceof ApiError && error.status < 500 && error.status !== 429) break;

      const delay = Math.min(baseDelay * Math.pow(2, attempt) + Math.random() * 1000, maxDelay);
      await new Promise(r => setTimeout(r, delay));
    }
  }
  throw lastError!;
}
```

## React Query Integration

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

function useUser(userId: string) {
  return useQuery({
    queryKey: ['user', userId],
    queryFn: () => api.get<User>(`/users/${userId}`),
    staleTime: 5 * 60 * 1000,
    retry: (count, error) => !(error instanceof ApiError && error.status === 404) && count < 3,
  });
}

function useUpdateUser() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<User> }) =>
      api.patch<User>(`/users/${id}`, data),
    onSuccess: (user) => {
      queryClient.setQueryData(['user', user.id], user);
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
  });
}
```

## Python (httpx)

```python
import httpx
from dataclasses import dataclass

@dataclass
class ApiConfig:
    base_url: str
    timeout: float = 10.0
    headers: dict = None

class ApiClient:
    def __init__(self, config: ApiConfig):
        self.client = httpx.AsyncClient(
            base_url=config.base_url,
            timeout=config.timeout,
            headers=config.headers or {}
        )

    async def get(self, endpoint: str, params: dict = None) -> dict:
        response = await self.client.get(endpoint, params=params)
        response.raise_for_status()
        return response.json()

    async def post(self, endpoint: str, data: dict = None) -> dict:
        response = await self.client.post(endpoint, json=data)
        response.raise_for_status()
        return response.json()

    async def __aenter__(self): return self
    async def __aexit__(self, *args): await self.client.aclose()
```
