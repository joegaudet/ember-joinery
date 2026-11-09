# ember-classic

Joinery in a classic ember-cli app (ember-cli and ember-auto-import 2, no Vite). CI runs its
smoke test to prove the v2 addons, their CSS and the primitives (their macros, modifiers, test
waiters and Floating UI) work outside Embroider, and an add-on too: Code Block, whose Shiki
ember-auto-import splits out to load on demand.

```bash
pnpm --filter ember-classic test
```
