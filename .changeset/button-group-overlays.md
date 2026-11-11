---
'@ember-joinery/ember': minor
---

A Dropdown Menu's, Popover's, Select's, Tooltip's or other overlay's trigger, and a Combobox's
input, joins a `ButtonGroup` as upstream's does: `button-group.css` restates the group's rules (joined corners,
one border between parts, the last part's rounded end, a select trigger's `w-fit`, a focused
part's raised `z-index`) one overlay root down, since Joinery's overlay roots are elements with
`display: contents` where Radix's (and Base UI's Combobox) render none. Likewise an `InputGroup` addon that is an
overlay's trigger narrows the input's padding beside it, as an addon of its own does.
