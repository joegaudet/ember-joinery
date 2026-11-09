# Sonner

An opinionated toast component for Ember.

<Example @name="sonner-demo" @title="Sonner" />

## About

[Sonner](https://sonner.emilkowal.ski) is built and maintained by
[emilkowalski](https://twitter.com/emilkowalski). Joinery's is a port of it, sonner 2.0.7, the
version upstream renders: the same `toast()`, the same `<Toaster>` arguments, the same markup and
the same CSS, with shadcn's look on top. It is Joinery's only toast; the
[Toast](/components/toast.md) page says why.

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)); it includes
sonner's. Then add the Toaster, once, to your application template:

```gts
// app/templates/application.gts
import { Toaster } from '@ember-joinery/ember'

<template>
  <main>{{outlet}}</main>
  <Toaster />
</template>
```

## Usage

```gts
import { toast } from '@ember-joinery/ember'
```

```gts
toast('Event has been created.')
```

`toast()` works from anywhere: a component's action, a route, a plain function. In a template,
call it from a function of your own, as the examples do, or bind its arguments with `fn`:

```gts
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { Button, toast } from '@ember-joinery/ember'

<template>
  <Button {{on "click" (fn toast "Event has been created." undefined)}}>Show Toast</Button>
</template>
```

(The `undefined` keeps the click event out of `toast`'s options.)

Toasts belong to the app, not the page: `toast()` shows them in the app whose `<Toaster>` is
rendered, so each test has its own (see [Testing](#testing)). `toastsFor(this)` names the app
from anything with an owner: `toastsFor(this).success('Saved')`.

## Types

<Example @name="sonner-types" @title="Types" />

## Description

<Example @name="sonner-description" @title="Description" />

## Position

Use the `position` option to change the position of the toast.

<Example @name="sonner-position" @title="Position" />

The Toaster's `@position` sets where toasts go when they don't say (`bottom-right` by default,
as sonner's). Each position in use gets a list of its own.

## API Reference

See the [Sonner API Reference](https://sonner.emilkowal.ski/getting-started) for more
information. Joinery's arguments are sonner's props, as `@` arguments; where sonner takes a
React node (a title, an icon, a custom toast), Joinery takes text or a component.

### Toaster

| Argument              | Type                                | Default              | What it does                                                                                                                |
| --------------------- | ----------------------------------- | -------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `@position`           | `ToastPosition`                     | `bottom-right`       | Where toasts show, unless a toast says                                                                                      |
| `@theme`              | `'light'` \| `'dark'` \| `'system'` | the page's           | Dark while `<html>` has the `dark` class, as upstream's follows next-themes                                                 |
| `@richColors`         | `boolean`                           |                      | Colours toasts by type (success green, error red…)                                                                          |
| `@expand`             | `boolean`                           |                      | Shows the stack expanded, not only on hover                                                                                 |
| `@duration`           | `number` (ms)                       | `4000`               | How long toasts show                                                                                                        |
| `@visibleToasts`      | `number`                            | `3`                  | How many show at once                                                                                                       |
| `@gap`                | `number` (px)                       | `14`                 | The space between expanded toasts                                                                                           |
| `@closeButton`        | `boolean`                           |                      | Gives every toast a close button                                                                                            |
| `@invert`             | `boolean`                           |                      | Dark toasts on a light theme, light on a dark one                                                                           |
| `@offset`             | `string` \| `number` \| per side    | `24px`               | The space from the viewport's edges                                                                                         |
| `@mobileOffset`       | `string` \| `number` \| per side    | `16px`               | The same, on screens 600px wide or less                                                                                     |
| `@hotkey`             | `string[]`                          | `['altKey', 'KeyT']` | The keys that expand and focus the stack                                                                                    |
| `@dir`                | `'ltr'` \| `'rtl'` \| `'auto'`      | where the Toaster is | The lists' direction                                                                                                        |
| `@swipeDirections`    | `SwipeDirection[]`                  | its position's sides | Which ways a toast can be swiped off                                                                                        |
| `@icons`              | `ToastIcons`                        | lucide's             | A component per type (`success`, `info`, `warning`, `error`, `loading`), and `close`                                        |
| `@toastOptions`       | `ToastOptions`                      |                      | Options for every toast: `className`, `classNames`, `duration`, `style`, `unstyled`, `closeButton`, `closeButtonAriaLabel`… |
| `@style`              | `{ [property]: string }`            | upstream's tokens    | Styles for each list, such as sonner's `--normal-bg`                                                                        |
| `@containerAriaLabel` | `string`                            | `Notifications`      | The region's name, before the hotkey                                                                                        |
| `@id`                 | `string`                            |                      | Shows only the toasts made with this `toasterId`                                                                            |
| `@name`               | `string`                            |                      | Its name, for `ToasterHarness`                                                                                              |

`@icons`, `@style` and `@toastOptions.classNames` add to upstream's (its lucide icons, its
`--normal-bg: var(--popover)` tokens, its `jn-toast` class) rather than replacing them.
Attributes, such as `class`, go on each list, as sonner's `className` does.

### toast()

| Call                                                                          | What it shows                                                                                  |
| ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| `toast(message, options?)`                                                    | A toast. Returns its id                                                                        |
| `toast.success(message, options?)`                                            | A success toast; also `info`, `warning`, `error` and `message`                                 |
| `toast.loading(message, options?)`                                            | A loading toast, which stays until you update or dismiss it                                    |
| `toast.promise(promise, { loading, success, error, description?, finally? })` | Loading while it waits, then `success` (given the result) or `error`. Returns `{ id, unwrap }` |
| `toast.custom(Component, options?)`                                           | A toast drawn by your component, which gets `@id` and `@dismiss`                               |
| `toast.dismiss(id?)`                                                          | Closes the toast with that id, or every toast                                                  |
| `toast.getHistory()`, `toast.getToasts()`                                     | Every toast made; those not dismissed                                                          |

Call `toast()` again with a toast's `id` to update it in place, as a loading toast turns into
its outcome. sonner's `toast.promise()` returns the id with `unwrap` on it; Joinery's returns
`{ id, unwrap }`, so the id stays a plain id.

### Toast options

| Option                                                                 | Type                              | What it does                                                                 |
| ---------------------------------------------------------------------- | --------------------------------- | ---------------------------------------------------------------------------- |
| `description`                                                          | `string` \| component             | A line under the title                                                       |
| `action`, `cancel`                                                     | `{ label, onClick }` \| component | A button. It closes the toast; an action's `event.preventDefault()` keeps it |
| `id`                                                                   | `string` \| `number`              | Its id, to update or dismiss it later                                        |
| `duration`                                                             | `number` (ms)                     | How long it shows; `Infinity` keeps it                                       |
| `position`                                                             | `ToastPosition`                   | Where it shows                                                               |
| `icon`                                                                 | component \| `null`               | Its icon, in place of its type's; `null` for none                            |
| `closeButton`                                                          | `boolean`                         | A close button, whatever the Toaster says                                    |
| `dismissible`                                                          | `boolean`                         | `false`: no swipe, no close button                                           |
| `richColors`, `invert`                                                 | `boolean`                         | As the Toaster's, for this toast                                             |
| `onDismiss`, `onAutoClose`                                             | `(toast) => void`                 | Called when it is closed, or when its time runs out                          |
| `className`, `classNames`, `descriptionClassName`, `style`, `unstyled` |                                   | Its styling, as sonner's                                                     |
| `toasterId`                                                            | `string`                          | The Toaster (`@id`) that shows it                                            |
| `testId`                                                               | `string`                          | Rendered as `data-testid`                                                    |

### Data attributes

The markup is sonner's, so sonner's CSS and its documented selectors work:

| Element              | Attributes                                                                                                                                                                                                                                   |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `<section>` (region) | `aria-live="polite"`, `aria-label`, `data-test-jn="toaster"`, `data-test-jn-name`                                                                                                                                                            |
| `<ol>` (each list)   | `class="toaster group"`, `data-sonner-toaster`, `data-sonner-theme`, `data-y-position`, `data-x-position`, `dir`, `data-test-jn-part="list"`, `data-test-jn-value` (its position)                                                            |
| `<li>` (each toast)  | `class="jn-toast"`, `data-sonner-toast`, `data-type`, `data-styled`, `data-mounted`, `data-front`, `data-visible`, `data-expanded`, `data-removed`, `data-swiping`, `data-rich-colors`… `data-test-jn="toast"`, `data-test-jn-name` (its id) |
| inside a toast       | `[data-icon]`, `[data-content]`, `[data-title]`, `[data-description]`, `[data-button][data-action]`, `[data-button][data-cancel]`, `[data-close-button]`, each with a `data-test-jn-part`                                                    |

Each list is in the browser's [top layer](/primitives/top-layer.md), so toasts show above
dialogs, sheets and popovers. When a toast arrives, its list moves above any layer opened since.
Pressing a toast closes no [dismissable layer](/primitives/dismiss.md).

## Keyboard interactions

| Key         | What it does                                        |
| ----------- | --------------------------------------------------- |
| `Alt` + `T` | Expands the stack and moves focus to it (`@hotkey`) |
| `Tab`       | Moves between the toasts and their buttons          |
| `Escape`    | Collapses the stack, when focus is in it            |

When focus leaves the stack it goes back where it was before. Focus in a toast also expands
the stack and pauses the timers, as the pointer does (sonner pauses only for the pointer), so
a keyboard user has the time a pointer user has.

## Accessibility

- The region is a `<section>` with `aria-live="polite"`: screen readers announce each toast as
  it arrives. It is named `Notifications alt+T`; with two Toasters on a page, give each its own
  `@containerAriaLabel`.
- The timers pause while the pointer or focus is on the stack, and when the page is hidden.
  For a message the user must act on, give it `duration: Infinity`, or use an Alert Dialog.
- An action needs a label that says what it does (`Undo`), and a close button's name is
  `Close toast` unless `@toastOptions.closeButtonAriaLabel` says otherwise.
- With `@richColors`, sonner's success and info text are slightly under 4.5:1 against their
  backgrounds at the toasts' 13px. To meet WCAG AA, set darker `--success-text` and
  `--info-text` in your CSS on `[data-sonner-toaster]`.
- Animations stop with `prefers-reduced-motion`, in sonner's CSS.

## Testing

`ToasterHarness` from `@ember-joinery/test-support` drives a `<Toaster>`, and `ToastHarness`
one toast in it. Toasts belong to the app, so give each test its own with
`setupToaster(hooks)`, and render a `<Toaster>` beside what you test (your app renders its own
in the application template, which a rendering test doesn't):

```gts
import { module, test } from 'qunit'
import { setupRenderingTest } from 'my-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { Toaster } from '@ember-joinery/ember'
import { ButtonHarness, ToasterHarness, setupToaster } from '@ember-joinery/test-support'

module('saving', function (hooks) {
  setupRenderingTest(hooks)
  setupToaster(hooks)

  test('it says so', async function (assert) {
    await render(<template><SaveButton /><Toaster /></template>)
    await new ButtonHarness('save').click()
    const toast = new ToasterHarness().toast()
    assert.strictEqual(toast.title, 'Saved')
    await toast.clickAction() // Undo
  })
})
```

`setupToaster(hooks)` points `toast()` at each test's owner from the start of the test, so a
toast made before the Toaster renders still goes to the test, and never to the next one.

| `ToasterHarness`                            | What it is                                                          |
| ------------------------------------------- | ------------------------------------------------------------------- |
| `toasts`, `titles`                          | Every toast (a `ToastHarness` each), and their titles, newest first |
| `toast(id or { index })`                    | One toast: the newest, or by its id or index                        |
| `count`                                     | How many it shows, not counting any on their way out                |
| `positions`, `lists`                        | The positions in use, and their `<ol>`s                             |
| `theme`, `label`                            | `light` or `dark`; the region's name                                |
| `isExpanded`                                | Whether the stack is expanded                                       |
| `hover(position?)`, `unhover()`             | Puts the pointer on a list, and takes it off                        |
| `pressHotkey(keys?)`                        | Presses Alt+T (or the given `@hotkey`)                              |
| `waitForToast(title?)`, `waitForNoToasts()` | Waits for a toast (one made later), or for all to go                |

| `ToastHarness`                                                                       | What it is               |
| ------------------------------------------------------------------------------------ | ------------------------ |
| `id`, `title`, `description`, `type`, `position`                                     | What it shows, and where |
| `isFront`, `isVisible`, `isExpanded`, `isMounted`, `isRemoved`                       | Its place in the stack   |
| `isLoading`, `isPromise`, `isDismissible`, `isStyled`, `hasRichColors`, `isInverted` | Its kind                 |
| `icon`, `action`, `cancel`, `closeButton`                                            | Its parts, or `null`     |
| `clickAction()`, `clickCancel()`, `close()`                                          | Presses its buttons      |
| `swipe(direction, { distance, duration })`                                           | Swipes it with a pointer |
| `focus()`                                                                            | Focuses it               |

An exit takes 200ms, which tests wait for: once `close()` or `clickAction()` resolves, the
toast is gone. A toast's own timer doesn't hold tests up; give the Toaster a short `@duration`
and `waitForNoToasts()` to test it.

## Upstream

shadcn/ui's [Sonner](https://ui.shadcn.com/docs/components/radix/sonner), from
`apps/v4/registry/bases/radix/ui/sonner.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, on
[sonner](https://github.com/emilkowalski/sonner) 2.0.7 (its `toast`, `Toaster` and
`styles.css`). The headless part is [Toast](/primitives/toast.md) in the primitives.
