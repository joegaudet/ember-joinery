# ember-vite-basic

Joinery in a Vite (Embroider) Ember app: the packages imported into `.gjs` files and
`joinery.css` imported once from `app/app.js`, plus an add-on, `@ember-joinery/code-block`, whose
Code Block loads Shiki on demand. CI builds it and runs its smoke test.

```bash
pnpm --filter ember-vite-basic test
```
