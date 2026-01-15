---
name: state-manager
description: Implements state management following project patterns. Supports React Context, Zustand, Redux, and more.
---

# State Management Patterns

## When to Use What

| Pattern | Best For |
|---------|----------|
| useState | Local component state |
| useReducer | Complex local state with multiple sub-values |
| Context | Global state shared across many components |
| Zustand | Simple global state, minimal boilerplate |
| Redux Toolkit | Large apps with complex state |
| Jotai/Recoil | Atomic state management |
| TanStack Query | Server state (API data) |

## React Context + useReducer

```typescript
import { createContext, useContext, useReducer, type ReactNode, type Dispatch } from 'react';

interface User { id: string; name: string; email: string; }
interface AuthState { user: User | null; loading: boolean; error: string | null; }

type AuthAction =
  | { type: 'LOGIN_START' }
  | { type: 'LOGIN_SUCCESS'; payload: User }
  | { type: 'LOGIN_ERROR'; payload: string }
  | { type: 'LOGOUT' };

function authReducer(state: AuthState, action: AuthAction): AuthState {
  switch (action.type) {
    case 'LOGIN_START': return { ...state, loading: true, error: null };
    case 'LOGIN_SUCCESS': return { user: action.payload, loading: false, error: null };
    case 'LOGIN_ERROR': return { user: null, loading: false, error: action.payload };
    case 'LOGOUT': return { user: null, loading: false, error: null };
    default: return state;
  }
}

interface AuthContextValue {
  state: AuthState;
  dispatch: Dispatch<AuthAction>;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(authReducer, { user: null, loading: true, error: null });

  const login = async (email: string, password: string) => {
    dispatch({ type: 'LOGIN_START' });
    try {
      const user = await api.post<User>('/auth/login', { email, password });
      dispatch({ type: 'LOGIN_SUCCESS', payload: user });
    } catch (error) {
      dispatch({ type: 'LOGIN_ERROR', payload: error.message });
      throw error;
    }
  };

  const logout = () => dispatch({ type: 'LOGOUT' });

  return <AuthContext.Provider value={{ state, dispatch, login, logout }}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
}
```

## Zustand

```typescript
import { create } from 'zustand';
import { persist, devtools } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';

interface CartItem { id: string; name: string; price: number; quantity: number; }
interface CartStore {
  items: CartItem[];
  isOpen: boolean;
  addItem: (item: Omit<CartItem, 'quantity'>) => void;
  removeItem: (id: string) => void;
  updateQuantity: (id: string, quantity: number) => void;
  clearCart: () => void;
  toggleCart: () => void;
}

export const useCartStore = create<CartStore>()(
  devtools(
    persist(
      immer((set) => ({
        items: [],
        isOpen: false,
        addItem: (item) => set((state) => {
          const existing = state.items.find((i) => i.id === item.id);
          if (existing) existing.quantity += 1;
          else state.items.push({ ...item, quantity: 1 });
        }),
        removeItem: (id) => set((state) => { state.items = state.items.filter((i) => i.id !== id); }),
        updateQuantity: (id, quantity) => set((state) => {
          const item = state.items.find((i) => i.id === id);
          if (item) item.quantity = Math.max(0, quantity);
        }),
        clearCart: () => set((state) => { state.items = []; }),
        toggleCart: () => set((state) => { state.isOpen = !state.isOpen; }),
      })),
      { name: 'cart-storage' }
    ),
    { name: 'CartStore' }
  )
);

// Selectors
export const useCartTotal = () => useCartStore((s) => s.items.reduce((sum, i) => sum + i.price * i.quantity, 0));
export const useCartCount = () => useCartStore((s) => s.items.reduce((sum, i) => sum + i.quantity, 0));
```

## Redux Toolkit

```typescript
import { createSlice, configureStore, type PayloadAction } from '@reduxjs/toolkit';
import { TypedUseSelectorHook, useDispatch, useSelector } from 'react-redux';

interface CounterState { value: number; history: number[]; }

const counterSlice = createSlice({
  name: 'counter',
  initialState: { value: 0, history: [] } as CounterState,
  reducers: {
    increment: (state) => { state.history.push(state.value); state.value += 1; },
    decrement: (state) => { state.history.push(state.value); state.value -= 1; },
    incrementByAmount: (state, action: PayloadAction<number>) => { state.history.push(state.value); state.value += action.payload; },
    reset: (state) => { state.history = []; state.value = 0; },
  },
});

export const { increment, decrement, incrementByAmount, reset } = counterSlice.actions;
export const store = configureStore({ reducer: { counter: counterSlice.reducer } });

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
export const useAppDispatch: () => AppDispatch = useDispatch;
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;
```

## Vue 3 Pinia

```typescript
import { defineStore } from 'pinia';

export const useCounterStore = defineStore('counter', {
  state: () => ({ count: 0, history: [] as number[] }),
  getters: {
    doubleCount: (state) => state.count * 2,
    lastValue: (state) => state.history[state.history.length - 1] ?? 0,
  },
  actions: {
    increment() { this.history.push(this.count); this.count++; },
    decrement() { this.history.push(this.count); this.count--; },
    async fetchCount() { this.count = (await api.get('/count')).count; },
  },
});
```

## Svelte Stores

```typescript
import { writable, derived } from 'svelte/store';

export const count = writable(0);

function createCounter() {
  const { subscribe, set, update } = writable(0);
  return {
    subscribe,
    increment: () => update((n) => n + 1),
    decrement: () => update((n) => n - 1),
    reset: () => set(0),
  };
}

export const counter = createCounter();
export const doubled = derived(count, ($count) => $count * 2);
```
