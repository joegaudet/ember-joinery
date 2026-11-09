# Alert

Displays a callout for user attention.

<Example @name="alert-demo" @title="Alert" />

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Alert } from '@ember-joinery/ember'
```

## Usage

```gts
import { Info } from 'lucide'
import { Alert, Button, Icon } from '@ember-joinery/ember'

<template>
  <Alert as |a|>
    <Icon @icon={{Info}} />
    <a.Title>Heads up!</a.Title>
    <a.Description>
      You can add components and dependencies to your app using the cli.
    </a.Description>
    <a.Action>
      <Button @variant="outline">Enable</Button>
    </a.Action>
  </Alert>
</template>
```

## Composition

Use the following composition to build an `Alert`. Its parts are yielded (`a.Title`), so they
need no import of their own:

```text
Alert
├── Icon
├── a.Title
├── a.Description
└── a.Action
```

## Basic

A basic alert with an icon, title and description.

<Example @name="alert-basic" @title="Basic" />

## Destructive

Use `@variant="destructive"` to create a destructive alert.

<Example @name="alert-destructive" @title="Destructive" />

## Action

Use `a.Action` to add a button or other action element to the alert.

<Example @name="alert-action" @title="Action" />

## Custom Colors

You can customize the alert colors by adding custom classes such as
`bg-amber-50 dark:bg-amber-950` to the `Alert` component. In a Tailwind app, a utility class
on the alert wins over its style, as here; without Tailwind, set the colours in your own CSS,
which wins too (Joinery's rules are in the `joinery` layer, below your own).

<Example @name="alert-colors" @title="Custom Colors" />

## RTL

Joinery's styles use logical properties, so an alert lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)): the icon moves to the
right, and the action to the left.

<Example @name="alert-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Alert

The `Alert` component displays a callout for user attention.

| Argument   | Type                         | Default     | What it does                                       |
| ---------- | ---------------------------- | ----------- | -------------------------------------------------- |
| `@variant` | `"default" \| "destructive"` | `"default"` | How it looks                                       |
| `@as`      | tag name                     | `div`       | The tag to render                                  |
| `@name`    | `string`                     |             | Its name, for `AlertHarness` (`data-test-jn-name`) |

It takes attributes on its element: give it `role="status"` in place of upstream's `alert` for
news that can wait. Put an icon first, so it takes the first column beside the text.

### The parts

`Alert` yields its parts. Each takes `@as`, a tag to render instead of `div`
(`<a.Title @as="h3">`), and attributes, `class` included.

| Part            | What it is                                                                                  |
| --------------- | ------------------------------------------------------------------------------------------- |
| `a.Title`       | The title of the alert, beside the icon                                                     |
| `a.Description` | The description or content of the alert, muted                                              |
| `a.Action`      | An action element (like a button), positioned absolutely in the top inline-end of the alert |

### The part modifiers

Each part is yielded as a modifier too, to make an element or component of your own that part,
with the same classes and attributes: `{{a.title}}`, `{{a.description}}` and `{{a.action}}`.

```gts
<Alert as |a|>
  <h3 {{a.title}}>Heads up!</h3>
</Alert>
```

### Data attributes

| Element         | Attribute           | Value                                                |
| --------------- | ------------------- | ---------------------------------------------------- |
| `Alert`         | `class`             | `jn-alert jn-alert-variant-<variant>`, `group/alert` |
|                 | `data-slot`         | `alert`                                              |
|                 | `role`              | `alert`                                              |
|                 | `data-variant`      | its `@variant`                                       |
|                 | `data-test-jn`      | `alert`                                              |
|                 | `data-test-jn-name` | its `@name`                                          |
| `a.Title`       | `class`             | `jn-alert-title`                                     |
|                 | `data-slot`         | `alert-title`                                        |
|                 | `data-test-jn-part` | `title`                                              |
| `a.Description` | `class`             | `jn-alert-description`                               |
|                 | `data-slot`         | `alert-description`                                  |
|                 | `data-test-jn-part` | `description`                                        |
| `a.Action`      | `class`             | `jn-alert-action`                                    |
|                 | `data-slot`         | `alert-action`                                       |
|                 | `data-test-jn-part` | `action`                                             |

Upstream's alert sets no `data-variant`; Joinery's does, as every component with a `@variant`.

## Keyboard interactions

None of its own. An alert doesn't take focus, so it doesn't interrupt what the user is doing
([APG alert pattern](https://www.w3.org/WAI/ARIA/apg/patterns/alert/)). A button in its action
is in the tab order as usual.

## Accessibility

- The `alert` role makes a screen reader announce the alert when it appears. Use it for what is
  urgent; for anything else, `role="status"` is announced politely, or `role` of your own.
- An alert rendered with the page is read with the page; to announce one, render it when the
  event happens.
- The icon is decorative (an `<Icon>` without `@label`), since the title says what it means.
- The destructive description is upstream's colour, 90% of `--destructive` on `--card`, which
  measures 4.49:1 in the default theme, a hair under WCAG AA's 4.5:1 for small text. Joinery
  keeps shadcn's style as it is; to pass, give the description the full colour, with
  `class="text-destructive"` in a Tailwind app, or in your own CSS:

  ```css
  [data-slot='alert'][data-variant='destructive'] > [data-slot='alert-description'] {
    color: var(--destructive);
  }
  ```

## Testing

`AlertHarness` from `@ember-joinery/test-support` finds an alert (`data-test-jn="alert"`):

```ts
import { AlertHarness, ButtonHarness } from '@ember-joinery/test-support'

const alert = new AlertHarness('payment') // <Alert @name="payment">
assert.strictEqual(alert.title, 'Payment failed')
await alert.find(ButtonHarness).click()
```

| Member        | What it is                                       |
| ------------- | ------------------------------------------------ |
| `title`       | Its title's text, or `''`                        |
| `description` | Its description's text, or `''`                  |
| `text`        | All the text it shows                            |
| `variant`     | Its `@variant`                                   |
| `role`        | Its role: `alert`, unless you gave it another    |
| `hasIcon`     | Whether it shows an icon                         |
| `action`      | The action's element (throws when there is none) |

## Upstream

shadcn/ui's [Alert](https://ui.shadcn.com/docs/components/radix/alert), from
`apps/v4/registry/bases/radix/ui/alert.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
