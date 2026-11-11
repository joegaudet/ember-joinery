---
'@ember-joinery/primitives': patch
---

`anchor()` and `{{anchorTo}}` set the anchor's size (`--jn-anchor-width`, `--jn-anchor-height`)
before they measure the floating element, and the Floating UI fallback places it again when
those properties change its size, as Radix's Popper does. So an element as wide as its anchor (a
Dropdown Menu's content) is placed at its own size the first time, and doesn't resize after it is
placed. A transition of the element's own on the properties that place it is cut short, so it
doesn't slide into place, and the browser's "ResizeObserver loop" message isn't reported as an
error.
