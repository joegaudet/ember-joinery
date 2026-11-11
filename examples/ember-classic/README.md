# ember-classic

Joinery in a classic ember-cli app (ember-cli and ember-auto-import 2, no Vite). CI runs its
smoke test to prove the v2 addons, their CSS and the primitives (their macros, modifiers, test
waiters and Floating UI) work outside Embroider, and add-ons too: Code Block, whose Shiki
ember-auto-import splits out to load on demand, the Carousel, on Embla, the File Upload, on
ember-file-upload, a data table, on TanStack Table's core, the Rich Text Editor, on Tiptap and
ProseMirror, the DatePicker, on ember-power-calendar (a v2 addon with a service of its own,
and ember-concurrency), and Masked Input and Phone Input, on Maskito and libphonenumber-js.

```bash
pnpm --filter ember-classic test
```
