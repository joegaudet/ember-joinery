---
'@ember-joinery/tiptap': major
'@ember-joinery/ember': minor
---

`@ember-joinery/tiptap` is a new opt-in add-on, on Tiptap 3 and its StarterKit:
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
