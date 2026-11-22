# @ember-joinery/tiptap

## 1.0.0

### Major Changes

- a73065d: `@ember-joinery/tiptap` is a new opt-in add-on, on Tiptap 3 and its StarterKit:
  `RichTextEditor`, a rich-text editor in shadcn's look. Its box is an Input Group, with the
  toolbar as its block-start addon and the document where its textarea would be. The toolbar is
  WAI-ARIA's toolbar (one tab stop, the arrow keys, Home and End between its controls, flipped
  right to left): a Dropdown Menu for the text style (a paragraph or a heading, of
  `@headingLevels`), Toggle Group items for bold, italic, underline, strikethrough and code and
  for lists, quotes and code blocks, and ghost Buttons for undo and redo (`aria-disabled` with
  nothing to do), each with a Tooltip naming it and its shortcut (in `aria-keyshortcuts` too), and
  Separators between the groups; `@toolbar` picks the controls. A press with the pointer keeps
  the document's focus and selection; from the keyboard, focus stays in the toolbar. It stores
  HTML, or Tiptap's JSON with `@output="json"` (`''` or `null` when empty), controlled or not
  (`@value`, `@defaultValue`, `@onValueChange`); a new `@value` replaces the document without a
  change. The document is a multi-line `textbox` that a `<FieldLabel for>` names; it takes
  `@placeholder`, `@disabled`, `@readonly` (no toolbar), `@invalid`, `@required` and
  `@describedBy`, and `@starterKit`, `@extensions` and `@onCreate` reach Tiptap. Every string is an
  argument (`@labels`). `toPlainText()` reads HTML and JSON alike. Its `/test-support` has
  `RichTextEditorHarness`. `@ember-joinery/ember`'s style sheets style its parts (the editor's
  type, the toolbar's wrapping); nothing in the core packages imports it.

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

- a53c07b: Type checks in package source use `@sindresorhus/is` (`isString`, `isFunction`, …) instead of `typeof`, and a lint rule keeps it that way. `@sindresorhus/is` is a new runtime dependency, so `ember-joinery add` now installs it into the app for most components, `icon` included. `isNumber` rejects `NaN`, so a `NaN` reaching a numeric check now takes the non-number branch.
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
