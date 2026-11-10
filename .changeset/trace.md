---
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Trace` is shadcn's Trace, the building block for reasoning, tool calls and sources: a list of
`TraceLine`s (an icon, a title, a description, and `@status` `running`, `error` or `pending`,
which colours, dims or shimmers it), whose parts are yielded and exported (`TraceIcon`,
`TraceTitle`, `TraceDescription`), and `TraceCollapsible`, a row that expands, with its trigger
(a chevron after the line that turns as it opens, which `@icon` replaces) and its content,
controlled (`@open`, `@onOpenChange`) or not (`@defaultOpen`). A trace styles any link or
trigger that wraps a line. `@ember-joinery/test-support` adds `TraceHarness`,
`TraceLineHarness` and `TraceCollapsibleHarness`.
