# ember-tailwind

Joinery in a Vite (Embroider) Ember app that also uses Tailwind CSS v4, through
`@tailwindcss/vite`. Its Tailwind entry point (`app/styles/app.css`) names Joinery's cascade
layer before Tailwind's, so utility classes override Joinery's rules. CI builds it and runs its
smoke test.

```bash
pnpm --filter ember-tailwind test
```
