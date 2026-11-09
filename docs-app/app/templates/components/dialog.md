# Dialog

A window overlaid on either the primary window or another dialog window, rendering the content
underneath inert.

<Example @name="dialog-demo" @title="Dialog" />

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Dialog } from '@ember-joinery/ember'
```

## Usage

```gts
<Dialog as |d|>
  <d.Trigger>Open</d.Trigger>
  <d.Content>
    <d.Header>
      <d.Title>Are you absolutely sure?</d.Title>
      <d.Description>
        This action cannot be undone. This will permanently delete your account and remove your
        data from our servers.
      </d.Description>
    </d.Header>
  </d.Content>
</Dialog>
```

`<Dialog>` yields its parts. Where upstream wraps your own element in a part with `asChild`
(`<DialogTrigger asChild><Button>`), give your element the part's modifier instead:

```gts
import { Button, Dialog } from '@ember-joinery/ember'

<template>
  <Dialog as |d|>
    <Button @variant="outline" {{d.trigger}}>Edit profile</Button>
    <d.Content>
      <d.Header>
        <d.Title>Edit profile</d.Title>
        <d.Description>Make changes to your profile here.</d.Description>
      </d.Header>
      <d.Footer>
        <Button @variant="outline" {{d.close}}>Cancel</Button>
        <Button {{on "click" this.save}}>Save changes</Button>
      </d.Footer>
    </d.Content>
  </Dialog>
</template>
```

Its state is its own, or yours: pass `@open` and `@onOpenChange` to control it, or
`@defaultOpen` to start it open. It also yields `isOpen`, and `open`, `toggle` and `setOpen` to
open and close it from your own code, such as a keyboard shortcut.

The content is rendered where you put it, and shown in the browser's top layer, above
everything else on the page, so it needs no portal. Its ancestors' `dir`, theme and CSS
variables reach it, and a `<form>` around the dialog holds the content's fields too (upstream's
portal moves them out of it), so a submit button in the content submits that form.

## Composition

Use the following composition to build a `Dialog`:

```text
Dialog
├── Trigger
└── Content
    ├── Header
    │   ├── Title
    │   └── Description
    └── Footer
```

## Custom Close Button

Replace the default close control with your own button.

<Example @name="dialog-close-button" @title="Custom Close Button" />

A Button of your own closes the dialog with the `close` modifier (`<Button {{d.close}}>`), as
upstream's `DialogClose asChild` does.

## No Close Button

Use `@showCloseButton={{false}}` to hide the close button.

<Example @name="dialog-no-close-button" @title="No Close Button" />

## Sticky Footer

Keep actions visible while the content scrolls.

<Example @name="dialog-sticky-footer" @title="Sticky Footer" />

The scrolling region takes focus (`tabindex="0"`), so a keyboard can scroll it; upstream's
doesn't, and the accessibility audit every example runs asks for it.

## Scrollable Content

Long content can scroll while the header stays in view.

<Example @name="dialog-scrollable-content" @title="Scrollable Content" />

## RTL

Joinery's styles use logical properties, so a dialog lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)): the close button moves to
the top left, and the dialog stays centred.

<Example @name="dialog-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Dialog

| Argument        | Type                            | Default | What it does                                                                          |
| --------------- | ------------------------------- | ------- | ------------------------------------------------------------------------------------- |
| `@open`         | `boolean`                       |         | Whether it is open, when you control it                                               |
| `@defaultOpen`  | `boolean`                       | `false` | Whether it starts open, when it controls itself                                       |
| `@onOpenChange` | `(open: boolean) => void`       |         | Called when it opens or closes, or asks to                                            |
| `@modal`        | `boolean`                       | `true`  | Inert page, trapped focus and an overlay; `false` leaves the page usable              |
| `@onClose`      | `(returnValue: string) => void` |         | Called when it closes itself, with a `<form method="dialog">`'s button value, or `''` |
| `@name`         | `string`                        |         | Its name, for `DialogHarness` (`data-test-jn-name`)                                   |

It renders an element with `display: contents`, and yields:

| Yield         | What it is                                                                    |
| ------------- | ----------------------------------------------------------------------------- |
| `Trigger`     | A `<button>` that opens and closes it                                         |
| `Content`     | The dialog, with its overlay and close button                                 |
| `Header`      | A `<div>` for the title and description                                       |
| `Footer`      | A `<div>` for the actions                                                     |
| `Title`       | An `<h2>` that names it                                                       |
| `Description` | A `<p>` that describes it                                                     |
| `Close`       | An unstyled `<button>` that closes it                                         |
| `trigger`     | The trigger's modifier, for your own element: `<Button {{d.trigger}}>`        |
| `close`       | The close modifier, for your own element: `<Button {{d.close}}>`              |
| `isOpen`      | Whether it is open                                                            |
| `isModal`     | Whether it is modal                                                           |
| `open`        | Opens it                                                                      |
| `toggle`      | Opens or closes it                                                            |
| `setOpen`     | Opens (`true`) or closes (`false`) it                                         |
| `returnValue` | The `value` of the button that submitted a `<form method="dialog">` inside it |

A modifier on a `<button>` of yours that has no `type` gives it `type="button"`, as Radix's parts
do, so it doesn't submit a form around it.

### Content

| Argument                | Type                             | Default      | What it does                                                    |
| ----------------------- | -------------------------------- | ------------ | --------------------------------------------------------------- |
| `@showCloseButton`      | `boolean`                        | `true`       | Show the close button in the corner                             |
| `@closeLabel`           | `string`                         | `"Close"`    | The close button's name for screen readers                      |
| `@closeIcon`            | a `lucide` icon                  | lucide's `x` | The close button's icon (upstream's `XIcon`)                    |
| `@onOpenAutoFocus`      | `(event: Event) => void`         |              | Before focus moves in; `preventDefault()` to move it yourself   |
| `@onCloseAutoFocus`     | `(event: Event) => void`         |              | Before focus goes back; `preventDefault()` to send it elsewhere |
| `@onEscapeKeyDown`      | `(event: KeyboardEvent) => void` |              | Escape was pressed; `preventDefault()` keeps it open            |
| `@onPointerDownOutside` | `(event: CustomEvent) => void`   |              | A press outside; `preventDefault()` keeps it open               |
| `@onFocusOutside`       | `(event: CustomEvent) => void`   |              | Focus moved outside; `preventDefault()` keeps it open           |
| `@onInteractOutside`    | `(event: CustomEvent) => void`   |              | Either of the two above                                         |
| `@forceMount`           | `boolean`                        |              | Keep it rendered while closed, to animate it yourself           |
| `@as`                   | tag name                         | `div`        | The tag to render                                               |

Its attributes, such as `class`, go on the dialog. The overlay is rendered with it.

### Footer

| Argument           | Type      | Default   | What it does                                |
| ------------------ | --------- | --------- | ------------------------------------------- |
| `@showCloseButton` | `boolean` | `false`   | Add an outline Close button after its block |
| `@closeLabel`      | `string`  | `"Close"` | That button's text                          |

Trigger, Close, Title and Description take `@as` for another tag, and attributes.

### Data attributes

| Part         | `class`                                | `data-slot`          | Also                                                   |
| ------------ | -------------------------------------- | -------------------- | ------------------------------------------------------ |
| Root         |                                        |                      | `data-test-jn="dialog"`, `data-test-jn-name`           |
| Trigger      |                                        | `dialog-trigger`     | `data-state`, `aria-haspopup`, `aria-expanded`         |
| Overlay      | `jn-dialog-overlay`                    | `dialog-overlay`     | `data-state`, `popover`                                |
| Content      | `jn-dialog-content`                    | `dialog-content`     | `data-state`, `role="dialog"`, `aria-modal`, `popover` |
| Close button | `jn-dialog-close` and a ghost Button's | `dialog-close`       | `data-test-jn-part="close-button"`                     |
| Header       | `jn-dialog-header`                     | `dialog-header`      |                                                        |
| Footer       | `jn-dialog-footer`                     | `dialog-footer`      |                                                        |
| Title        | `jn-dialog-title jn-font-heading`      | `dialog-title`       | `id`, which the content's `aria-labelledby` names      |
| Description  | `jn-dialog-description`                | `dialog-description` | `id`, which the content's `aria-describedby` names     |
| Close        |                                        | `dialog-close`       |                                                        |

`data-state` is `open` or `closed`. The content and overlay animate in and out on it, and stay
until their closing animation ends.

## Keyboard interactions

| Key              | What it does                                                                |
| ---------------- | --------------------------------------------------------------------------- |
| `Space`, `Enter` | On the trigger: opens it                                                    |
| `Tab`            | Moves to the next focusable element in the dialog; from the last, the first |
| `Shift` + `Tab`  | Moves to the previous one; from the first, the last                         |
| `Esc`            | Closes it, and focus goes back to the trigger                               |

That is the [APG dialog pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/).

## Accessibility

- The content has the `dialog` role, is named by its Title (`aria-labelledby`) and described
  by its Description (`aria-describedby`). Give every dialog a Title; to hide it, put it in a
  [`<VisuallyHidden>`](/primitives/visually-hidden.md). In development, a dialog without one
  says so.
- When it opens, focus moves to its first focusable element that isn't a link (or the dialog
  itself), and when it closes, back to the trigger.
- A modal dialog keeps focus inside, and makes the rest of the page inert, as a modal
  `<dialog>` does: nothing behind it can be focused, clicked or read aloud. Radix hides it with
  `aria-hidden`; Joinery uses `inert`, so a button behind isn't left focusable while hidden.
  Live regions (`aria-live`), such as a toast's, are left alone. The page doesn't scroll behind
  it (see [Scroll Lock](/primitives/scroll-lock.md)).
- The close button is named by `@closeLabel`; give it in the page's language.

## Testing

`DialogHarness` from `@ember-joinery/test-support` drives a `<Dialog>`, and follows its content
into the top layer:

```ts
import { ButtonHarness, DialogHarness, child } from '@ember-joinery/test-support'

class EditProfile extends DialogHarness {
  static named = 'edit-profile' // <Dialog @name="edit-profile">
  @child(ButtonHarness, 'save') declare save: ButtonHarness
}

const dialog = new EditProfile()
await dialog.open()
assert.strictEqual(dialog.label, 'Edit profile')
await dialog.save.click()
await dialog.close()
assert.dom(dialog.trigger).isFocused()
```

| Member            | What it is                                                                  |
| ----------------- | --------------------------------------------------------------------------- |
| `trigger`         | The trigger                                                                 |
| `content`         | The content, or `null` while closed                                         |
| `overlay`         | The overlay, or `null`                                                      |
| `title`           | The title, or `null`                                                        |
| `description`     | The description, or `null`                                                  |
| `closeButton`     | The close button in the corner, or `null`                                   |
| `isOpen`          | The trigger's `aria-expanded` (or, without one, the content's `data-state`) |
| `isModal`         | The content's `aria-modal`                                                  |
| `role`            | The content's role                                                          |
| `label`           | Its accessible name: the title's text                                       |
| `descriptionText` | Its accessible description                                                  |
| `isInTopLayer`    | Whether the content is in the top layer                                     |
| `hasFocus`        | Whether focus is inside                                                     |
| `open()`          | Clicks the trigger, unless it is open                                       |
| `close()`         | Clicks the close button, or presses Escape                                  |
| `pressEscape()`   | Presses Escape inside it                                                    |
| `pressOutside()`  | Presses the overlay (or, for a non-modal dialog, outside every layer)       |

`settled()` waits for the closing animation and for focus to go back, so a test needs no timers.

## Upstream

shadcn/ui's [Dialog](https://ui.shadcn.com/docs/components/radix/dialog), from
`apps/v4/registry/bases/radix/ui/dialog.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, on
Radix's Dialog. The headless part is [Dialog](/primitives/dialog.md) in
`@ember-joinery/primitives`, which covers ember-primitives' Dialog and Modal too.
