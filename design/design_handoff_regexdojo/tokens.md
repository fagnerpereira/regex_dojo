# Design tokens — RegexDojo

## Colors

| Token | Hex | Use |
|---|---|---|
| `violet-600` | `#7c3aed` | primary actions, active states, links |
| `violet-700` | `#6d28d9` | primary hover, gradient end |
| `violet-50` | `#f5f0ff` | light chip/tag backgrounds |
| `violet-25` | `#faf7ff` | panel/section backgrounds |
| `violet-100` | `#efeaf9` / `#f0ebfa` | hairline borders |
| `ink` | `#211b3a` | primary text |
| `ink-soft` | `#2a2350` | secondary dark text (on tinted bg) |
| `slate` | `#6b6488` | secondary/muted text |
| `slate-light` | `#9a93b5` | tertiary/placeholder text |
| `success` | `#22c55e` (text `#15803d`, bg `#dcfce7`) | done / valid states |
| `warning` | `#f59e0b` (text `#b45309`, bg `#fef3c7`) | in-progress states |
| `danger` | text `#b91c1c`, bg `#fef2f2`, border `#fecaca` | invalid regex |
| `pink` | `#f472b6` → `#db2777` | avatar gradient accent |
| `editor-bg` | `#1c1830` | dark code/editor chrome |
| `editor-text` | `#e9e4ff` | text on editor-bg |
| `mark-bg` | `#fde68a` (text `#7c2d12`) | default match highlight |

Dark ("neon dojo") scheme, if you build the alt theme: bg `#0e0a1f`, card `#1a1530`, border `#2c2350`.

## Typography
- **Display / headings**: `Baloo 2`, weights 500/600/700/800
- **Body / UI**: `Inter`, weights 400/500/600/700/800
- **Code / mono** (patterns, XP numbers in some spots): `JetBrains Mono`, weights 400/500/700

Scale used: 11–12px (labels/badges), 13–15px (body), 17–19px (section headers), 22–26px (card titles), 34px (hero H1).

## Radius
- Cards: `26px` (`rounded-[26px]`, or add a `2xl` custom size)
- Buttons / inputs: `14px`
- Pills / badges: fully rounded (`rounded-full`)
- Small tiles / avatars: `12–16px`, avatars are circular

## Shadows
- Card: `0 2px 4px rgba(60,30,120,.05), 0 14px 40px rgba(60,30,120,.07)`
- Primary button: `0 6px 16px rgba(124,58,237,.3)`

## Tailwind config fragment

```js
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        dojo: {
          violet: { DEFAULT: '#7c3aed', dark: '#6d28d9', light: '#f5f0ff', wash: '#faf7ff', border: '#efeaf9' },
          ink: '#211b3a',
          slate: '#6b6488',
          success: { DEFAULT: '#22c55e', text: '#15803d', bg: '#dcfce7' },
          warning: { DEFAULT: '#f59e0b', text: '#b45309', bg: '#fef3c7' },
          danger: { text: '#b91c1c', bg: '#fef2f2', border: '#fecaca' },
          editor: { bg: '#1c1830', text: '#e9e4ff' },
        },
      },
      fontFamily: {
        display: ['"Baloo 2"', 'system-ui', 'sans-serif'],
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['"JetBrains Mono"', 'ui-monospace', 'monospace'],
      },
      borderRadius: {
        card: '26px',
      },
      boxShadow: {
        card: '0 2px 4px rgba(60,30,120,.05), 0 14px 40px rgba(60,30,120,.07)',
        'btn-primary': '0 6px 16px rgba(124,58,237,.3)',
      },
    },
  },
};
```
