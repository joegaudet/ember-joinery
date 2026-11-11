---
'@ember-joinery/primitives': minor
---

`native-value` gives an `<input>`, `<textarea>` or `<select>` Radix's value pattern:
`{{nativeValue value= defaultValue= onValueChange=}}`. Controlled, the control shows `value` and
a change the caller doesn't pass back is undone; uncontrolled, it keeps its own value. A form
reset goes back to the starting value and says so, and a select shows its value again when its
options change.
