# Alert Dialog

A modal dialog that interrupts the user with important content and expects a response.

<Example @name="alert-dialog-demo" @title="Alert Dialog" />

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { AlertDialog } from '@ember-joinery/ember'
```

## Usage

```gts
<AlertDialog as |d|>
  <Button @variant="outline" {{d.trigger}}>Show Dialog</Button>
  <d.Content>
    <d.Header>
      <d.Title>Are you absolutely sure?</d.Title>
      <d.Description>
        This action cannot be undone. This will permanently delete your account from our
        servers.
      </d.Description>
    </d.Header>
    <d.Footer>
      <d.Cancel>Cancel</d.Cancel>
      <d.Action {{on "click" this.deleteAccount}}>Continue</d.Action>
    </d.Footer>
  </d.Content>
</AlertDialog>
```

Where upstream's trigger wraps your Button with `asChild`, give the Button the `trigger`
modifier. Cancel and Action are Buttons, and both close the dialog; listen for the Action's
click to act on it. Its state is its own, or yours with `@open` and `@onOpenChange`, as a
[Dialog](/components/dialog.md)'s is.

Name the block parameter something other than a tag you use inside it: with `as |a|`, an `<a>`
link in the content would be a call to it.

## Composition

Use the following composition to build an `AlertDialog`:

```text
AlertDialog
├── Trigger
└── Content
    ├── Header
    │   ├── Media
    │   ├── Title
    │   └── Description
    └── Footer
        ├── Cancel
        └── Action
```

## Basic

A basic alert dialog with a title, description, and cancel and continue buttons.

<Example @name="alert-dialog-basic" @title="Basic" />

## Small

Use `@size="sm"` to make the alert dialog smaller.

<Example @name="alert-dialog-small" @title="Small" />

## Media

Use the `Media` part to add a media element such as an icon or image to the alert dialog.

<Example @name="alert-dialog-media" @title="Media" />

## Small with Media

Use `@size="sm"` to make the alert dialog smaller and the `Media` part to add a media element
such as an icon or image to the alert dialog.

<Example @name="alert-dialog-small-media" @title="Small with Media" />

## Destructive

Use the `Action` part with `@variant="destructive"` to add a destructive action button to the
alert dialog.

<Example @name="alert-dialog-destructive" @title="Destructive" />

## RTL

Joinery's styles use logical properties, so an alert dialog lays itself out right to left
inside any element with `dir="rtl"` (see [Direction](/primitives/direction.md)): its text starts
on the right, and Cancel comes first, on the right.

<Example @name="alert-dialog-rtl" @title="RTL" @dir="rtl" />

## API Reference

### AlertDialog

| Argument        | Type                            | Default | What it does                                             |
| --------------- | ------------------------------- | ------- | -------------------------------------------------------- |
| `@open`         | `boolean`                       |         | Whether it is open, when you control it                  |
| `@defaultOpen`  | `boolean`                       | `false` | Whether it starts open, when it controls itself          |
| `@onOpenChange` | `(open: boolean) => void`       |         | Called when it opens or closes, or asks to               |
| `@onClose`      | `(returnValue: string) => void` |         | Called when it closes itself                             |
| `@name`         | `string`                        |         | Its name, for `AlertDialogHarness` (`data-test-jn-name`) |

It is always modal. It renders an element with `display: contents`, and yields `Trigger`,
`Content`, `Header`, `Footer`, `Media`, `Title`, `Description`, `Action` and `Cancel`, the
`trigger`, `action` and `cancel` modifiers for elements of your own, and `isOpen`, `open` and
`setOpen`.

### Content

| Argument | Type                | Default     | What it does                                                            |
| -------- | ------------------- | ----------- | ----------------------------------------------------------------------- |
| `@size`  | `"default" \| "sm"` | `"default"` | `sm` is narrower, centres its header, and puts its buttons side by side |

It takes the same focus and dismissal handlers as a [Dialog's Content](/components/dialog.md),
`@forceMount` and `@as`. It has no close button: Cancel is the way out.

### Action and Cancel

| Argument   | Type                  | Default                                    | What it does                  |
| ---------- | --------------------- | ------------------------------------------ | ----------------------------- |
| `@variant` | a Button's `@variant` | `"default"` (Action), `"outline"` (Cancel) | How it looks                  |
| `@size`    | a Button's `@size`    | `"default"`                                | How big it is                 |
| `@name`    | `string`              |                                            | Its name, for `ButtonHarness` |

They are [Buttons](/components/button.md), and take attributes and listeners.

### Data attributes

| Part        | `class`                                                 | `data-slot`                | Also                              |
| ----------- | ------------------------------------------------------- | -------------------------- | --------------------------------- |
| Root        |                                                         |                            | `data-test-jn="alert-dialog"`     |
| Trigger     |                                                         | `alert-dialog-trigger`     | `data-state`, `aria-expanded`     |
| Overlay     | `jn-alert-dialog-overlay`                               | `alert-dialog-overlay`     | `data-state`                      |
| Content     | `jn-alert-dialog-content`, `group/alert-dialog-content` | `alert-dialog-content`     | `data-size`, `role="alertdialog"` |
| Header      | `jn-alert-dialog-header`                                | `alert-dialog-header`      |                                   |
| Media       | `jn-alert-dialog-media`                                 | `alert-dialog-media`       |                                   |
| Title       | `jn-alert-dialog-title jn-font-heading`                 | `alert-dialog-title`       | `id`, named by `aria-labelledby`  |
| Description | `jn-alert-dialog-description`                           | `alert-dialog-description` | `id`, named by `aria-describedby` |
| Footer      | `jn-alert-dialog-footer`                                | `alert-dialog-footer`      |                                   |
| Action      | `jn-alert-dialog-action` and a Button's                 | `alert-dialog-action`      | `data-variant`, `data-size`       |
| Cancel      | `jn-alert-dialog-cancel` and a Button's                 | `alert-dialog-cancel`      | `data-variant`, `data-size`       |

## Keyboard interactions

| Key              | What it does                                        |
| ---------------- | --------------------------------------------------- |
| `Space`, `Enter` | On the trigger: opens it, with focus on Cancel      |
| `Tab`            | Moves to the next button; from the last, the first  |
| `Shift` + `Tab`  | Moves to the previous one; from the first, the last |
| `Esc`            | Closes it, and focus goes back to the trigger       |

That is the [APG alert dialog pattern](https://www.w3.org/WAI/ARIA/apg/patterns/alertdialog/).

## Accessibility

- The content has the `alertdialog` role, named by its Title and described by its Description.
  Give it both; in development, one without them says so.
- Focus starts on Cancel, the choice that changes nothing, so Enter can't confirm by accident.
- A press outside doesn't close it: it waits for an answer. Escape does, as Cancel would.
- The page behind it is inert and doesn't scroll, as behind a modal [Dialog](/components/dialog.md).

## Testing

`AlertDialogHarness` from `@ember-joinery/test-support` drives an `<AlertDialog>`. It is a
`DialogHarness` (see [Dialog](/components/dialog.md)), with:

```ts
import { AlertDialogHarness } from '@ember-joinery/test-support'

const alert = new AlertDialogHarness('delete-account')
await alert.open()
assert.dom(alert.cancelButton).isFocused()
await alert.confirm()
assert.false(alert.isOpen)
```

| Member         | What it is                                   |
| -------------- | -------------------------------------------- |
| `actionButton` | The action                                   |
| `cancelButton` | Cancel                                       |
| `confirm()`    | Clicks the action                            |
| `cancel()`     | Clicks Cancel                                |
| `close()`      | Clicks Cancel, or presses Escape without one |

## Upstream

shadcn/ui's [Alert Dialog](https://ui.shadcn.com/docs/components/radix/alert-dialog), from
`apps/v4/registry/bases/radix/ui/alert-dialog.tsx` at shadcn-ui/ui@8ab2771, in the Nova style,
on Radix's AlertDialog. The headless part is [AlertDialog](/primitives/dialog.md) in
`@ember-joinery/primitives`.
