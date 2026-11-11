---
'@ember-joinery/ember': patch
---

Where a style sets `font-sans` or `font-mono` (Kbd's keys), the part takes the page's
`--font-sans` or `--font-mono` when it sets one, as upstream's take ui.shadcn.com's Geist, and
Tailwind's system stacks otherwise.
