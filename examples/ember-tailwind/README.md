# ember-tailwind

Joinery in a Vite (Embroider) Ember app that also uses Tailwind CSS v4, through
`@tailwindcss/vite`. Its Tailwind entry point (`app/styles/app.css`) declares the cascade
layers as `theme, base, joinery, components, utilities`: Joinery's rules sit above Tailwind's
preflight (in `base`), so its resets don't undo them, and below the utilities, so a utility
class on a component overrides them. CI builds it and runs its smoke test, which checks both.

```bash
pnpm --filter ember-tailwind test
```
