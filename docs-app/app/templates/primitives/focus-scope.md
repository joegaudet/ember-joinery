# Focus Scope

A focus scope moves focus into a part when it appears, can keep it there, and gives it back
when the part goes: what a dialog, a sheet or a modal menu needs. It is Radix's `FocusScope`,
and it does the focus trapping that ember-primitives gets from tabster's Modalizer.

<Example @name="focus-scope-trap" @title="A trapped panel" />

## Usage

```gts
import { FocusScope } from '@ember-joinery/primitives/focus-scope'

<template>
  {{#if this.open}}
    <FocusScope @trapped={{true}} @loop={{true}} role="dialog" aria-label="Edit profile">
      …
    </FocusScope>
  {{/if}}
</template>
```

- **When it appears**, focus moves to its first tabbable element that isn't a link (an input's
  text is selected), or to the scope itself when it has none. If focus is already inside, it
  stays.
- **`@loop`**: Tab from the last element goes to the first, and Shift+Tab from the first to
  the last.
- **`@trapped`**: Tab and Shift+Tab stop at the edges, and focus that leaves any other way (a
  click outside, a script) comes back to the element focused last inside. When the focused
  element is removed, focus goes to the scope. While it traps, two invisible focus guards sit at
  the ends of `<body>`, as Radix's do, so tabbing off the end of the page lands on something
  the trap can see.
- **When it goes**, focus returns to the element that had it when the scope appeared: the
  button that opened the dialog. It waits until the element has gone, as Radix does.

Scopes stack: one that appears while another is active pauses it, and the older one traps
again when the newer one goes, so a dialog opened from a dialog works.

The same thing on any element, as a modifier, or from a component's own code:

```gts
import { focusScope, createFocusScope } from '@ember-joinery/primitives/focus-scope'

<template>
  <div role="dialog" aria-label="Edit" {{focusScope trapped=true loop=true}}>…</div>
</template>
```

```ts
const scope = createFocusScope(element, { trapped: true })
scope.update({ trapped: false })
scope.destroy() // focus returns
```

The modifier gives the element `tabindex="-1"` when it has no tabindex of its own, so it can
take focus when it holds nothing else that can; with `createFocusScope`, give it one yourself.

`addFocusGuards()` puts the guards in on their own, for an overlay that isn't trapped but
should still see focus leave it; it returns the function that releases them, and the guards go
when the last holder releases them.

## API

| Argument              | Type                     | Default | What it does                                                  |
| --------------------- | ------------------------ | ------- | ------------------------------------------------------------- |
| `@trapped`            | `boolean`                | `false` | Keep focus inside                                             |
| `@loop`               | `boolean`                | `false` | Tab goes round from the last element to the first, and back   |
| `@onMountAutoFocus`   | `(event: Event) => void` |         | Before focus moves in; `preventDefault()` to move it yourself |
| `@onUnmountAutoFocus` | `(event: Event) => void` |         | Before focus returns; `preventDefault()` to send it elsewhere |
| `@as`                 | tag name                 | `div`   | The tag to render                                             |

The modifier takes the same arguments without the `@`. The element has `tabindex="-1"` and
`data-slot="focus-scope"`, and takes attributes.

## Keyboard interactions

| Key       | What it does                                                                          |
| --------- | ------------------------------------------------------------------------------------- |
| Tab       | The next tabbable element; from the last, the first (`@loop`) or nowhere (`@trapped`) |
| Shift+Tab | The previous one; from the first, the last (`@loop`) or nowhere (`@trapped`)          |

## Accessibility

A trapped scope is for content that is modal, such as a dialog: give it the role and the label
that say so. Content outside should be inert while it is open, which a `<dialog>` opened with
`showModal()` gives you; a focus scope only keeps the keyboard in.

## Testing

`FocusScope` wraps content, like `DirectionProvider`, so it isn't a component root for the
harnesses: the parts inside belong to the component around them. Test it through that
component, and press Tab with `tab()` from `@ember-joinery/test-support` (see
[Focus](/primitives/focus.md)):

```ts
await dialog.open()
assert.dom(dialog.firstField).isFocused()
await tab({ shift: true })
assert.dom(dialog.saveButton).isFocused()
await dialog.close()
assert.dom(dialog.trigger).isFocused()
```

Focus returns once the scope's element has gone, and `settled()` waits for it, so a test
needs no timers.
