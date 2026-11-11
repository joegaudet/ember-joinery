# Focus

Finding focusable elements, moving focus, and keeping it from falling to `<body>`. This is
what ember-primitives gets from [tabster](https://tabster.io/), without tabster: there is
nothing to set up, and Joinery's components have their keyboard support as soon as they
render.

<Example @name="focus-restore" @title="Focus that stays in the list" />

## Coming from ember-primitives

ember-primitives asks an app to call `setupTabster(this)` in its application route, and tests
to call `setupTabster(hooks)`, before its keyboard support works. Joinery needs neither. What
tabster does there, and where it is here:

| tabster (ember-primitives)                       | Joinery                                                            |
| ------------------------------------------------ | ------------------------------------------------------------------ |
| `setupTabster(this)`, `data-tabster` root        | Nothing to set up                                                  |
| Mover: arrow keys, `cyclic`, `memorizeCurrent`   | [Roving Focus](/primitives/roving-focus.md): `@loop`, the tab stop |
| `focusable: { isDefault }` (the selected tab)    | A roving item's `@active`; `restoreFocus`'s `preferred`            |
| Deloser: focus restored when its element goes    | `restoreFocus`, below                                              |
| Modalizer, focus trapping                        | [Focus Scope](/primitives/focus-scope.md): `@trapped`              |
| `focusable.findFirst`, `findLast`, `findNext`, … | `focusable`, below                                                 |
| `setupTabster(hooks)` in tests                   | Nothing; `tab()` from `@ember-joinery/test-support` for Tab        |

## Finding focusable elements

```ts
import { focusable } from '@ember-joinery/primitives/focus'

focusable.findAll({ container }) // what Tab reaches, in document order
focusable.findFirst({ container })
focusable.findLast({ container })
focusable.findNext({ container, currentElement }) // the next one after an element
focusable.findPrev({ container, currentElement })
focusable.findAll({ container, includeProgrammaticallyFocusable: true }) // tabindex="-1" too
focusable.isFocusable(element)
```

An element counts when it is enabled (a disabled `<fieldset>` disables what's in it), shown
(not `hidden`, not `display: none`, not `visibility: hidden`, not in a closed `<details>`), not
`inert`, and either Tab reaches it or, with `includeProgrammaticallyFocusable`, it has a
`tabindex` of its own. A link needs an `href`. Positive tabindexes don't reorder the results, as
in Radix and tabster. `accept` filters them further: `{ container, accept: el => … }`.

## Moving focus

```ts
import { focusElement, focusFirst } from '@ember-joinery/primitives/focus'

focusElement(input, { select: true }) // focus, and select an input's text
focusFirst([active, current, ...items]) // the first that takes focus
```

`focusFirst` tries each candidate until focus moves, and stops at the one that already has it,
as Radix's does, so "the items after this one" never moves focus past where it started. Both
take `preventScroll`.

## Keeping focus when its element goes

`{{restoreFocus}}` keeps focus from falling to `<body>` when the focused element inside is
removed, as tabster's Deloser does. In the example above, completing the focused task moves
focus to another task, not to the top of the page.

```gts
import { restoreFocus } from '@ember-joinery/primitives/focus'

<template>
  <ul {{restoreFocus}}>
    {{#each this.tasks as |task|}}
      <li><button type="button" {{on "click" (fn this.done task)}}>Done</button></li>
    {{/each}}
  </ul>
</template>
```

Focus moves to, in order:

1. `preferred`, if it is inside and can take focus (`{{restoreFocus preferred=this.selectedTab}}`);
2. the element focused most recently inside that is still there;
3. the first focusable element inside, or the element itself if it takes focus;
4. and when the element itself is removed with focus inside, the element focused most
   recently outside it, such as the trigger that opened a menu.

It only acts when the focused element was removed. Focus a user moves elsewhere, even to
`<body>` by clicking the page, stays where they put it. `onRestore=(fn …)` hears where focus is
about to go, and returning `false` from it leaves focus to you.

## API

| Modifier argument | Type                                     | What it does                           |
| ----------------- | ---------------------------------------- | -------------------------------------- |
| `preferred`       | `HTMLElement \| null`                    | The element to move focus to first     |
| `onRestore`       | `(next: HTMLElement) => boolean \| void` | Called first; `false` cancels the move |

## Testing

A test can't press the real Tab key, so `@ember-joinery/test-support` simulates it, and sends
other keys to whatever has focus:

```ts
import { pressKey, tab, tabOrder, typeKeys } from '@ember-joinery/test-support'

await tab() // keydown on the focused element; unless prevented, focus moves on
await tab({ shift: true })
tabOrder(form) // the elements Tab visits, in a browser's order
await pressKey('ArrowDown') // keydown and keyup on the focused element; true if prevented
await typeKeys('ba') // a key press per character, for typeahead
```

`tab()` follows a browser's rules: positive tabindexes first, then document order, one stop
per group of native radio buttons, and past the last element focus leaves the page (nothing is
focused afterwards). It leaves out the test runner's own controls. `pressKey` and `typeKeys`
send key events only, so they don't type into inputs or press buttons; use `typeIn` and
`click` for those.
