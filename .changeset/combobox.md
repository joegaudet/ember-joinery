---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`Combobox` is shadcn's Combobox, on Base UI's: `<Combobox @items={{…}} as |c|>` yields Input
(in its input group, with `@showTrigger`, `@showClear`, `@groupClass` for the group, and
an `Addon` it yields for an icon beside the input),
Trigger, TriggerIcon, Clear, Value, Content, List, Item, Group, Label, Collection, Empty,
Separator, Chips, Chip and ChipsInput. Typing filters `@items` (an `Intl.Collator` match anywhere in the label, or your
own `@filter`, or `@filter={{null}}` for results filtered elsewhere) and the arrow keys
highlight an item while focus stays in the input; `@multiple` shows the chosen items as chips,
`@autoHighlight` highlights the first match, and the input can sit inside the popup behind a
trigger of your own. `@ember-joinery/primitives/combobox` is the headless one, and
`@ember-joinery/test-support` adds `ComboboxHarness`.
