# Dialog

The headless parts under Joinery's [Dialog](/components/dialog.md),
[Sheet](/components/sheet.md) and [Alert Dialog](/components/alert-dialog.md): Radix's Dialog
and AlertDialog, with no styles. They also cover ember-primitives' `Dialog` and `Modal`.

<Example @name="dialog-headless" @title="A headless dialog" />

## Usage

```gts
import { Dialog } from '@ember-joinery/primitives/dialog'

<template>
  <Dialog as |d|>
    <d.Trigger>Edit profile</d.Trigger>
    <d.Overlay class="overlay" />
    <d.Content class="panel">
      <d.Title>Edit profile</d.Title>
      <d.Description>Make changes to your profile here.</d.Description>
      <d.Close>Done</d.Close>
    </d.Content>
  </Dialog>
</template>
```

While it is open:

- **The content is in the top layer** ([`topLayer`](/primitives/top-layer.md)), above
  everything else, with the overlay under it, and no portal: it stays where you render it, so
  its ancestors' direction, theme and forms reach it.
- **Escape closes it**, and so does a press outside the content: on the overlay, for a modal
  one ([`dismissable`](/primitives/dismiss.md)). A right click doesn't.
- **Focus moves in** to its first focusable element that isn't a link, or the content itself,
  and **goes back** to the trigger when it closes ([`focusScope`](/primitives/focus-scope.md)).
- **A modal dialog** (the default) also keeps focus inside, makes the rest of the page inert
  ([`inertOthers`](/primitives/hide-others.md)), as a modal `<dialog>` does, and its overlay
  stops the page scrolling ([`scrollLock`](/primitives/scroll-lock.md)).
- **A non-modal one** (`@modal={{false}}`) has no overlay and leaves the page usable: a press or
  focus outside closes it, and a press on the trigger toggles it.

The content and overlay animate out ([`Presence`](/primitives/presence.md)): when it closes,
they stay until an animation that `data-state="closed"` starts has ended.

The parts are popovers in the browser's top layer, and start from its popover styles (centred,
sized to fit, with a border and padding). Joinery's CSS resets those on its parts; style yours
over them, as the example does with utility classes.

### Your own elements

Each part takes `@as` for another tag, and the trigger, close, title and description have a
modifier for an element or component of your own, as Radix's `asChild` does. A `<button>` of
yours with no `type` gets `type="button"`:

```gts
<Dialog as |d|>
  <MyButton {{d.trigger}}>Edit</MyButton>
  <d.Content>
    <MyHeading {{d.title}}>Edit</MyHeading>
    <MyButton {{d.close}}>Done</MyButton>
  </d.Content>
</Dialog>
```

### State

Its state is its own, starting from `@defaultOpen`, or yours with `@open` and `@onOpenChange`
([controllable state](/primitives/controllable-state.md)). It yields `isOpen`, and `open`,
`toggle` and `setOpen` for your own code: a dialog with no trigger at all, opened by a keyboard
shortcut, works too.

### ember-primitives' Dialog and Modal

| ember-primitives                | Joinery                                                                                     |
| ------------------------------- | ------------------------------------------------------------------------------------------- |
| `<Modal as \|m\|>`, `m.Dialog`  | `<Dialog as \|d\|>`, `d.Content` (with `d.Overlay`)                                         |
| `m.open`, `m.close`, `m.isOpen` | `d.open`, `(fn d.setOpen false)`, `d.isOpen`                                                |
| `@open`                         | `@open` with `@onOpenChange`, or `@defaultOpen`                                             |
| `m.focusOnClose`                | Built in: focus goes back to the trigger, or to where it was                                |
| `@onClose(returnValue)`         | `@onClose(returnValue)`, from a `<form method="dialog">` inside it                          |
| Escape, `closedby`              | Escape and presses outside; `@onEscapeKeyDown` and `@onPointerDownOutside` can keep it open |
| The simple `<Dialog as \|d\|>`  | `<Dialog>` with no Trigger, opened with `d.open`                                            |

A `<form method="dialog">` in the content closes the dialog when it is submitted, and
`d.returnValue` (and `@onClose`) is the `value` of the button that submitted it.

## AlertDialog

`@ember-joinery/primitives/alert-dialog` is Radix's AlertDialog: always modal, with the
`alertdialog` role, focus on its Cancel when it opens, and no closing on a press outside.
Escape, Cancel and Action close it.

<Example @name="alert-dialog-headless" @title="A headless alert dialog" />

```gts
import { AlertDialog } from '@ember-joinery/primitives/alert-dialog'

<template>
  <AlertDialog as |d|>
    <d.Trigger>Delete file</d.Trigger>
    <d.Overlay />
    <d.Content>
      <d.Title>Delete this file?</d.Title>
      <d.Description>There is no undo.</d.Description>
      <d.Cancel>Keep it</d.Cancel>
      <d.Action {{on "click" this.delete}}>Delete</d.Action>
    </d.Content>
  </AlertDialog>
</template>
```

It yields a Dialog's parts but Close, with `Action` and `Cancel` (and the `action` and `cancel`
modifiers) in its place.

## API

### Dialog

| Argument        | Type                            | Default    | What it does                                                         |
| --------------- | ------------------------------- | ---------- | -------------------------------------------------------------------- |
| `@open`         | `boolean`                       |            | Whether it is open, when you control it                              |
| `@defaultOpen`  | `boolean`                       | `false`    | Whether it starts open, when it controls itself                      |
| `@onOpenChange` | `(open: boolean) => void`       |            | Called when it opens or closes, or asks to                           |
| `@modal`        | `boolean`                       | `true`     | Whether it is modal                                                  |
| `@onClose`      | `(returnValue: string) => void` |            | Called when it closes itself (Escape, outside, a close part, a form) |
| `@slot`         | `string`                        | `"dialog"` | What its parts' `data-slot`s start with, and its `data-test-jn`      |
| `@name`         | `string`                        |            | Its name, for `DialogHarness`                                        |

It renders an element with `display: contents` and yields `Trigger`, `Overlay`, `Content`,
`Title`, `Description` and `Close`, the `trigger`, `close`, `title` and `description`
modifiers, and `isOpen`, `isModal`, `open`, `toggle`, `setOpen` and `returnValue`.

### Content

| Argument                | Type                             | What it does                                                    |
| ----------------------- | -------------------------------- | --------------------------------------------------------------- |
| `@onOpenAutoFocus`      | `(event: Event) => void`         | Before focus moves in; `preventDefault()` to move it yourself   |
| `@onCloseAutoFocus`     | `(event: Event) => void`         | Before focus goes back; `preventDefault()` to send it elsewhere |
| `@onEscapeKeyDown`      | `(event: KeyboardEvent) => void` | Escape was pressed; `preventDefault()` keeps it open            |
| `@onPointerDownOutside` | `(event: CustomEvent) => void`   | A press outside; `preventDefault()` keeps it open               |
| `@onFocusOutside`       | `(event: CustomEvent) => void`   | Focus moved outside; `preventDefault()` keeps it open           |
| `@onInteractOutside`    | `(event: CustomEvent) => void`   | Either of the two above                                         |
| `@forceMount`           | `boolean`                        | Keep it rendered while closed                                   |
| `@as`                   | tag name                         | The tag to render (`div`)                                       |

The overlay takes `@forceMount` and `@as`; Trigger and Close render a `<button>`, Title an
`<h2>` and Description a `<p>`, each with `@as`.

### Attributes

| Part        | Attributes                                                                                                          |
| ----------- | ------------------------------------------------------------------------------------------------------------------- |
| Trigger     | `aria-haspopup="dialog"`, `aria-expanded`, `aria-controls` (while open), `data-state`                               |
| Overlay     | `data-state`, `popover="manual"`, `data-test-jn-owner`                                                              |
| Content     | `role`, `aria-modal`, `aria-labelledby`, `aria-describedby`, `data-state`, `popover="manual"`, `data-test-jn-owner` |
| Title       | `id`                                                                                                                |
| Description | `id`                                                                                                                |

Each has `data-slot="<slot>-<part>"` (`dialog-content`) and `data-test-jn-part`.

## Keyboard interactions

| Key             | What it does                                                              |
| --------------- | ------------------------------------------------------------------------- |
| `Tab`           | The next focusable element; in a modal dialog, from the last to the first |
| `Shift` + `Tab` | The previous one; in a modal dialog, from the first to the last           |
| `Esc`           | Closes it                                                                 |

## Testing

`DialogHarness` and `AlertDialogHarness` from `@ember-joinery/test-support` drive the headless
parts as they do the styled ones: see [Dialog](/components/dialog.md) and
[Alert Dialog](/components/alert-dialog.md).

```ts
const dialog = new DialogHarness()
await dialog.open()
assert.true(dialog.isInTopLayer)
await dialog.pressEscape()
assert.dom(dialog.trigger).isFocused()
```
