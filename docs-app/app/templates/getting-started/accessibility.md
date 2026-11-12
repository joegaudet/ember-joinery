# Accessibility

How Joinery meets WCAG 2.2 AA, and how its tests check it.

Joinery's components target WCAG 2.2 AA. Each follows the WAI-ARIA Authoring Practices
pattern for its role: the roles, states and properties, the keyboard interactions and the
focus management. Every test ends in an axe audit, so the guide's examples, the components'
own tests and the pages of this guide are all checked on every pull request.

## What each component does for you

- **Keyboard.** Every component works without a pointer. Its page lists its keys under
  "Keyboard interactions": arrows and Home and End in menus, tabs, radio groups and sliders;
  typeahead in menus and selects; Escape to close what opens.
- **Focus.** Dialogs, sheets, drawers and popovers move focus in when they open, keep it
  inside while they are modal, and give it back to their trigger when they close.
- **Names and states.** Labels, descriptions, `aria-expanded`, `aria-selected`, `aria-checked`,
  `aria-invalid` and the rest are set from the component's state, so assistive technology
  hears what a sighted user sees.
- **A modal page is inert.** While a modal dialog or menu is open, the rest of the page is
  `inert`: it can't be clicked, focused or read until the modal closes.
- **Right to left.** The keyboard follows the direction as the layout does; see [RTL](rtl.md).

Each component's page has an "Accessibility" section for anything beyond its pattern.

## Where Joinery parts from upstream

Joinery keeps shadcn/ui's pixels. Where upstream's markup falls short of WCAG, Joinery fixes the
markup and leaves the look alone:

- **Progress** announces its value. Upstream's leaves it off, so it always reads as
  indeterminate.
- **Table** joins the tab order while it scrolls and holds nothing focusable, so a keyboard can
  scroll a wide table.
- **Dropdown Menu** and **Context Menu** make the page inert while they are modal, where Radix
  hides it with `aria-hidden` and leaves its buttons focusable.
- **Data Table** puts its sort on the header cell, in `aria-sort`, as the APG's sortable table
  does.

## Colour contrast

In shadcn's light themes, two of upstream's colours fall short of the 4.5:1 AA asks of small
text: [Kbd](/components/kbd.md)'s keys and the destructive [Badge](/components/badge.md).
Joinery keeps upstream's colours; each of those pages has the CSS that meets AA. Everything
around them is still audited.

## Test it in your app

`@ember-joinery/test-support`'s harnesses read a component's state through ARIA, as a screen
reader does, so a test written with them checks the ARIA contract as it goes. End each test in
an axe audit with [ember-a11y-testing](https://github.com/ember-a11y/ember-a11y-testing), as
Joinery's own tests do:

```ts
import { a11yAudit } from 'ember-a11y-testing/test-support'

test('the dialog opens and closes', async function (assert) {
  // … render, then drive it with its harness
  await a11yAudit()
})
```

See [Testing](testing.md) for the harnesses.
