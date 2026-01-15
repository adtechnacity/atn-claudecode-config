---
name: brand-designer
description: Expert in brand identity, logo design, and visual brand systems
version: 1.0.0
tags: [branding, logo-design, identity, visual-identity, brand-guidelines]
---

# Brand Designer Skill

Create cohesive brand identities, logos, and visual brand systems.

## Capabilities

**Brand Identity:** Logo design/variations, color palettes, typography, brand guidelines
**Visual Assets:** Business cards, letterheads, social templates, marketing materials
**Brand Strategy:** Positioning, target audience, competitor analysis, voice/tone

## Logo Design Process

### 1. Brand Discovery

Answer: Company purpose, target audience, brand values, desired feeling, colors/symbols to avoid.

### 2. Logo Concepts

| Type | Description | Examples |
|------|-------------|----------|
| Wordmark | Clean typography, company name focus | Google, Netflix |
| Lettermark | Distinctive initials | IBM, HBO |
| Icon + Wordmark | Symbol + name (most versatile) | Nike, Apple |

**Logo Component Example:**

```typescript
interface LogoProps {
  variant?: 'full' | 'icon' | 'wordmark'
  color?: 'primary' | 'white' | 'black'
  size?: number
}

export function Logo({ variant = 'full', color = 'primary', size = 40 }: LogoProps) {
  const colors = { primary: '#0066CC', white: '#FFFFFF', black: '#000000' }
  const fillColor = colors[color]

  if (variant === 'icon') {
    return (
      <svg width={size} height={size} viewBox="0 0 40 40" fill="none">
        <circle cx="20" cy="20" r="18" fill={fillColor} />
        <path d="M15 20 L25 15 L25 25 Z" fill="white" />
      </svg>
    )
  }
  // Full/wordmark variants follow same pattern
}
```

## Color Palette

```typescript
export const brandColors = {
  primary: {
    50: '#E6F0FF', 100: '#CCE0FF', 200: '#99C2FF', 300: '#66A3FF', 400: '#3385FF',
    500: '#0066CC', // Main
    600: '#0052A3', 700: '#003D7A', 800: '#002952', 900: '#001429'
  },
  secondary: {
    50: '#FFF4E6', 100: '#FFE9CC', 200: '#FFD399', 300: '#FFBD66', 400: '#FFA733',
    500: '#FF9100', // Main accent
    600: '#CC7400', 700: '#995700', 800: '#663A00', 900: '#331D00'
  },
  neutral: {
    50: '#F9FAFB', 100: '#F3F4F6', 200: '#E5E7EB', 300: '#D1D5DB', 400: '#9CA3AF',
    500: '#6B7280', 600: '#4B5563', 700: '#374151', 800: '#1F2937', 900: '#111827'
  },
  success: '#10B981', warning: '#F59E0B', error: '#EF4444', info: '#3B82F6'
}
```

**Usage Guidelines:**
- Primary: buttons, links, active states (WCAG AA on white)
- Secondary: CTAs, highlights
- Neutral hierarchy: 900 headings, 700 body, 500 secondary, 300 borders, 100 backgrounds

## Typography System

```css
:root {
  --font-sans: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
  --text-xs: 0.75rem; --text-sm: 0.875rem; --text-base: 1rem;
  --text-lg: 1.125rem; --text-xl: 1.25rem; --text-2xl: 1.5rem;
  --text-3xl: 1.875rem; --text-4xl: 2.25rem; --text-5xl: 3rem;
}
```

**Scale:** H1: 48px/Bold, H2: 36px/Semibold, Body: 16px/Regular, Caption: 14px/Regular

## Brand Guidelines Template

```markdown
# Brand Guidelines

## Logo Usage
- **Variations:** Full (marketing), Icon (favicon/avatars), Wordmark (contextual)
- **Clear space:** Height of first letter
- **Min size:** Digital 120px/40px icon, Print 1"/0.25"
- **Don'ts:** No rotation, color changes, effects, distortion

## Voice & Tone
- Professional but not corporate
- Technical but approachable
- Active voice, concise, use "we/you"
```

## Asset File Structure

```
brand-assets/
├── logo/ (svg/, png/@1x-3x, favicon/)
├── colors/palette.json
├── fonts/*.woff2
├── templates/ (social, business-card)
└── guidelines/brand-guidelines.pdf
```

## Favicon Generation

```typescript
import sharp from 'sharp'

async function generateFavicons() {
  for (const size of [16, 32, 48, 64, 128, 256]) {
    await sharp('logo-icon.svg').resize(size, size).png().toFile(`public/favicon-${size}x${size}.png`)
  }
}
```

## When to Use

- Creating brand identities, logos, visual systems
- Building brand guidelines and templates
- Ensuring brand consistency across assets
