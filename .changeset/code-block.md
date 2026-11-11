---
'@ember-joinery/code-block': major
'@ember-joinery/ember': minor
---

`@ember-joinery/code-block` is a new add-on: shadcn's Code Block, for code, terminal output and
diffs. `CodeBlock` yields a header, title, actions, a copy button, the content and its lines,
with line numbers (from any `@startLine`), wrapping, highlighted and diff lines, a `sm` size and a
`destructive` variant. `highlightedCode` highlights with Shiki's JavaScript engine, loading Shiki
and each language on first use, tokenizing only the new lines as code streams in, and rendering
ANSI colours; `highlightCode`, `registerLanguage` and `configureHighlighter` go with it. Its
`/test-support` has `CodeBlockHarness` and `setupClipboard()`. `@ember-joinery/ember`'s style
sheets style its parts.
