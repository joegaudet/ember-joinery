# @ember-joinery/code-block

## 1.1.0

### Patch Changes

- @ember-joinery/ember@1.1.0
  - @ember-joinery/primitives@1.1.0
  - @ember-joinery/test-support@1.1.0

## 1.0.0

### Major Changes

- a73065d: `@ember-joinery/code-block` is a new add-on: shadcn's Code Block, for code, terminal output and
  diffs. `CodeBlock` yields a header, title, actions, a copy button, the content and its lines,
  with line numbers (from any `@startLine`), wrapping, highlighted and diff lines, a `sm` size and a
  `destructive` variant. `highlightedCode` highlights with Shiki's JavaScript engine, loading Shiki
  and each language on first use, tokenizing only the new lines as code streams in, and rendering
  ANSI colours; `highlightCode`, `registerLanguage` and `configureHighlighter` go with it. Its
  `/test-support` has `CodeBlockHarness` and `setupClipboard()`. `@ember-joinery/ember`'s style
  sheets style its parts.

### Minor Changes

- 17c5b5c: The add-ons' built-in strings go through the app's translator, each package's in its own
  `<package>/messages`: Carousel's role descriptions, slide names (`{index} of {count}`) and step
  buttons; Code Block's Copy and Copied; File Upload's prompt, hint, drop label, its rejected,
  left-out, remove, retry and progress names, Upload failed and `FILE`; Phone Input's country
  picker's name; Power Calendar's month buttons, its calendars' names and the pickers' placeholder,
  trigger names and range (`{from} – {to}`); the Rich Text Editor's toolbar, text styles,
  tools and its shortcuts' Ctrl, Shift and Alt. An argument still wins. File Upload's, Phone Input's and Power Calendar's `@locale`
  default to the translator's. Chart and Data Table show no strings of their own.

### Patch Changes

- a73065d: Every package's tarball carries Joinery's `LICENSE.md` and `NOTICE`, with the licences and
  notices of what it ports (shadcn/ui, ember-primitives, sonner, recharts and the rest), copied in
  from the repository's root by the package's `prepack`.
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [17c5b5c]
- Updated dependencies [17c5b5c]
- Updated dependencies [99eab0c]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
- Updated dependencies [a73065d]
  - @ember-joinery/primitives@1.0.0
  - @ember-joinery/ember@1.0.0
  - @ember-joinery/test-support@1.0.0
