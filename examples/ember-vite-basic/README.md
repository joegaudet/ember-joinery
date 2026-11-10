# ember-vite-basic

Joinery in a Vite (Embroider) Ember app: the packages imported into `.gjs` files and
`joinery.css` imported once from `app/app.js`, plus five add-ons: `@ember-joinery/code-block`,
whose Code Block loads Shiki on demand, `@ember-joinery/carousel`, whose Carousel its smoke test
moves with `CarouselHarness`, `@ember-joinery/file-upload`, whose File Upload (on
ember-file-upload) it fills with `FileUploadHarness`, `@ember-joinery/data-table`, whose table (on
TanStack Table's core) it sorts with `DataTableHarness`, and `@ember-joinery/tiptap`, whose Rich
Text Editor (on Tiptap) it formats with `RichTextEditorHarness`. CI builds it and runs its smoke
test.

```bash
pnpm --filter ember-vite-basic test
```
