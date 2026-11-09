---
'@ember-joinery/primitives': minor
'@ember-joinery/test-support': minor
---

Focus, one subpath export each, ported from Radix and covering what ember-primitives gets from
tabster, with nothing to set up: `focus-scope` (`FocusScope`, `{{focusScope}}` and
`createFocusScope`: focus moves in, can be trapped or loop, and returns when the scope goes;
scopes stack, and trapped ones add focus guards), `roving-focus` (`RovingFocusGroup` and
`RovingFocus`: one tab stop, the arrow keys, Home and End, right to left, loop, a remembered and
an active item, a controlled tab stop), `typeahead` (`{{typeahead}}`, `Typeahead`,
`getNextMatch`) and `focus` (`focusable` queries, `focusFirst`, `focusElement`, and
`{{restoreFocus}}`, which keeps focus from falling to `<body>` when its element is removed).
`@ember-joinery/test-support` adds `tab()`, `tabOrder()`, `pressKey()`, `typeKeys()` and
`RovingFocusGroupHarness`.
