---
'@ember-joinery/primitives': minor
'@ember-joinery/ember': minor
'@ember-joinery/test-support': minor
---

`NavigationMenu` is shadcn's Navigation Menu, on Radix's: a `<nav>` whose `n.List` holds
`n.Item`s, each a `n.Link` or an `item.Trigger` and its `item.Content`. A trigger opens its
content on a click, or when the pointer rests on it (at once while another was just open); the
contents show in a viewport below the list that takes the open one's size and slides each in
from its trigger's side (`data-motion`), or below their own triggers with `@viewport={{false}}`.
Tab goes from an open trigger into its links and on, and the arrow keys, Home and End move
between triggers and links, for a trigger of your own (`{{item.trigger}}`) as for `item.Trigger`.
`n.Indicator` follows the open trigger, `n.Viewport` places the viewport yourself with
`@viewport={{false}}`, and `navigationMenuTriggerStyle()` gives a link the trigger's look, its
padding over the link's, as upstream's tailwind-merge gives it. Its state is
`@value`/`@defaultValue`/`@onValueChange`. `@ember-joinery/primitives/navigation-menu` is the
headless one, with `List`, `Item`, `Link`, `Indicator` and `Viewport`, and
`@ember-joinery/test-support` adds `NavigationMenuHarness`.
