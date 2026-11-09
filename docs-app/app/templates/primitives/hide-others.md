# Hide Others

Hides everything on the page but the elements you name, as the aria-hidden package does for
Radix: from assistive technology with `hideOthers`, or from everyone, the way a modal
`<dialog>` does, with `inertOthers`. A modal [Dialog](/primitives/dialog.md) makes the page
behind it inert this way.

<Example @name="hide-others-spotlight" @title="One card in the spotlight" />

## Usage

```gts
import { modifier } from 'ember-modifier'
import { inertOthers } from '@ember-joinery/primitives/hide-others'

const spotlight = modifier(element => inertOthers(element))

<template>
  <section {{spotlight}}>…</section>
</template>
```

Both take an element or a list of them, and return the function that puts everything back:

```ts
import { hideOthers, inertOthers } from '@ember-joinery/primitives/hide-others'

const undo = inertOthers([dialog, overlay])
undo()
```

- **What they change**: every element in `<body>` that isn't a target, inside one or above one.
  They walk down from `<body>`, and at each level mark the children that hold no target, so the
  targets' ancestors stay as they are.
- **`hideOthers`** sets `aria-hidden="true"` (and `data-aria-hidden`). Hidden elements can
  still take focus, so keep focus inside the targets ([`focusScope`](/primitives/focus-scope.md)).
- **`inertOthers`** sets `inert` (and `data-inert-ed`): nothing else can be focused, clicked or
  read aloud.
- **Live regions** (`aria-live`) and scripts are left alone, so an announcement outside, such
  as a toast's, is still heard.
- **Calls stack**: an element stays hidden until every call that hid it is undone, and one that
  was hidden before keeps its own attribute.

`{ parent }` limits them to one part of the page.

## API

| Function                            | What it does                                       |
| ----------------------------------- | -------------------------------------------------- |
| `hideOthers(targets, { parent? })`  | `aria-hidden` on everything else; returns the undo |
| `inertOthers(targets, { parent? })` | `inert` on everything else; returns the undo       |

`targets` is an element or a list of them (`null` and `undefined` in it are skipped); `parent`
is where to start, `<body>` by default.

## Accessibility

Use `inertOthers` for content that is modal: everything behind it is out of reach for every
user, as with a modal `<dialog>`. `hideOthers` hides the rest only from assistive technology,
which, without a focus trap, leaves keyboard users able to reach what screen reader users can't
hear, and leaves focusable elements inside `aria-hidden`, which an audit flags.

## Testing

Check the attributes: `assert.dom(sidebar).hasAttribute('inert')`. An inert element takes no
focus, so `focus()` on it leaves focus where it was.
