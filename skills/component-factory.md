---
name: component-factory
description: Creates UI components following best practices. Use when building new React, Vue, or Svelte components.
---

# Component Patterns

## React Component Structure

### Basic Component with TypeScript

```typescript
import { forwardRef, type ComponentPropsWithoutRef } from 'react';
import { cn } from '@/lib/utils';

interface ButtonProps extends ComponentPropsWithoutRef<'button'> {
  variant?: 'primary' | 'secondary' | 'ghost' | 'destructive';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', loading, children, disabled, ...props }, ref) => (
    <button
      ref={ref}
      className={cn(
        'inline-flex items-center justify-center rounded-md font-medium transition-colors',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2',
        'disabled:pointer-events-none disabled:opacity-50',
        {
          'bg-primary text-primary-foreground hover:bg-primary/90': variant === 'primary',
          'bg-secondary text-secondary-foreground hover:bg-secondary/80': variant === 'secondary',
          'hover:bg-accent hover:text-accent-foreground': variant === 'ghost',
          'bg-destructive text-destructive-foreground hover:bg-destructive/90': variant === 'destructive',
        },
        {
          'h-8 px-3 text-sm': size === 'sm',
          'h-10 px-4': size === 'md',
          'h-12 px-6 text-lg': size === 'lg',
        },
        className
      )}
      disabled={disabled || loading}
      {...props}
    >
      {loading && <svg className="mr-2 h-4 w-4 animate-spin" viewBox="0 0 24 24">...</svg>}
      {children}
    </button>
  )
);
Button.displayName = 'Button';
```

### Compound Component Pattern

```typescript
import { createContext, useContext, useState, type ReactNode } from 'react';

interface AccordionContextValue { openItems: string[]; toggle: (id: string) => void; }
const AccordionContext = createContext<AccordionContextValue | null>(null);

function useAccordion() {
  const context = useContext(AccordionContext);
  if (!context) throw new Error('Accordion components must be used within Accordion');
  return context;
}

interface AccordionProps { children: ReactNode; defaultOpen?: string[]; allowMultiple?: boolean; }

function Accordion({ children, defaultOpen = [], allowMultiple = false }: AccordionProps) {
  const [openItems, setOpenItems] = useState<string[]>(defaultOpen);
  const toggle = (id: string) => setOpenItems((prev) =>
    prev.includes(id) ? prev.filter((item) => item !== id) : allowMultiple ? [...prev, id] : [id]
  );
  return <AccordionContext.Provider value={{ openItems, toggle }}><div className="divide-y">{children}</div></AccordionContext.Provider>;
}

function AccordionItem({ id, children }: { id: string; children: ReactNode }) {
  const { openItems } = useAccordion();
  return <div data-state={openItems.includes(id) ? 'open' : 'closed'}>{children}</div>;
}

function AccordionTrigger({ id, children }: { id: string; children: ReactNode }) {
  const { openItems, toggle } = useAccordion();
  return (
    <button onClick={() => toggle(id)} aria-expanded={openItems.includes(id)} className="flex w-full items-center justify-between py-4">
      {children}
      <ChevronIcon className={cn('transition-transform', openItems.includes(id) && 'rotate-180')} />
    </button>
  );
}

function AccordionContent({ id, children }: { id: string; children: ReactNode }) {
  const { openItems } = useAccordion();
  if (!openItems.includes(id)) return null;
  return <div className="pb-4">{children}</div>;
}

Accordion.Item = AccordionItem;
Accordion.Trigger = AccordionTrigger;
Accordion.Content = AccordionContent;
export { Accordion };
```

### Polymorphic Component

```typescript
import { type ElementType, type ComponentPropsWithoutRef } from 'react';

type BoxProps<T extends ElementType> = { as?: T } & ComponentPropsWithoutRef<T>;

function Box<T extends ElementType = 'div'>({ as, ...props }: BoxProps<T>) {
  const Component = as || 'div';
  return <Component {...props} />;
}

// Usage: <Box as="article" className="p-4">Content</Box>
```

## Component Checklist

- Props typed with interface
- Default prop values
- Forwards ref for native elements
- Spreads remaining props
- Supports className
- Handles loading/disabled/error states
- Accessible (keyboard, aria, focus)
- Has displayName
- Uses semantic HTML
- Supports dark mode

## File Structure

```
components/
  Button/
    Button.tsx
    Button.test.tsx
    index.ts
  # Or flat: ui/button.tsx, input.tsx, card.tsx
```

## Vue 3 Component

```vue
<script setup lang="ts">
interface Props { variant?: 'primary' | 'secondary' | 'ghost'; size?: 'sm' | 'md' | 'lg'; loading?: boolean; disabled?: boolean; }
const props = withDefaults(defineProps<Props>(), { variant: 'primary', size: 'md', loading: false, disabled: false });
const emit = defineEmits<{ click: [event: MouseEvent] }>();
const classes = computed(() => ['btn', `btn-${props.variant}`, `btn-${props.size}`, { 'btn-loading': props.loading }]);
</script>

<template>
  <button :class="classes" :disabled="disabled || loading" @click="emit('click', $event)">
    <span v-if="loading" class="spinner" />
    <slot />
  </button>
</template>
```

## Svelte Component

```svelte
<script lang="ts">
  export let variant: 'primary' | 'secondary' | 'ghost' = 'primary';
  export let size: 'sm' | 'md' | 'lg' = 'md';
  export let loading = false;
  export let disabled = false;
  $: classes = ['btn', `btn-${variant}`, `btn-${size}`, loading && 'btn-loading'].filter(Boolean).join(' ');
</script>

<button class={classes} disabled={disabled || loading} on:click {...$$restProps}>
  {#if loading}<span class="spinner" />{/if}
  <slot />
</button>
```
