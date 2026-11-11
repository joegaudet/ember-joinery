---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`ResizablePanelGroup`, `ResizablePanel` and `ResizableHandle` are shadcn's Resizable: panel
groups side by side or stacked, nested, with handles a pointer drags and the keyboard moves (APG's
window splitter), sizes in percent, pixels or font units, collapsible panels, and a layout to save
(`@defaultLayout`, `@onLayoutChanged`). They sit on `Resizable`, `ResizablePanel` and
`ResizableHandle` from `@ember-joinery/primitives/resizable`, which follow react-resizable-panels'
API and cover ember-primitives' `Resizable`. `@ember-joinery/test-support` adds
`ResizableHarness`, and `sendPointer()` for real pointer events.
