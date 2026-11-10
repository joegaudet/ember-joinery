---
'@ember-joinery/primitives': minor
---

A part's attribute can be a function of the element's own value, so a part merges a list with
the caller's instead of replacing it: `'aria-describedby': own => joinTokens(mine, own)`, asked
again whenever either side changes. `joinTokens()` joins space-separated lists without repeats.
A Questionnaire item uses it to keep a caller's `aria-describedby` and `aria-keyshortcuts`, as
upstream merges them.
