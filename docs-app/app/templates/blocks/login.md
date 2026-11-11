# Login

A simple login form.

<Example @name="login-01" @title="login-01" @block={{true}} @blockHeight={{930}} />

## Installation

Blocks aren't exported from a package: copy the block's files into your app. It uses
`@ember-joinery/ember`:

```bash
pnpm add @ember-joinery/ember
```

and Tailwind's utilities for its layout (`flex`, `max-w-sm`, `md:p-10`…), as upstream's does: see
[Installation](/getting-started/installation.md) for a Tailwind app.

## Files

| File                      | What it is                                                                                  |
| ------------------------- | ------------------------------------------------------------------------------------------- |
| `login-01.gts`            | The page: the form, centred, no wider than `max-w-sm`                                       |
| `login-01/login-form.gts` | `LoginForm`: a [Card](/components/card.md) around the form's [Fields](/components/field.md) |

`LoginForm` puts your attributes on its outer `<div>`, after its own classes, as upstream's
spreads its props there.

## Accessibility

- Each [Input](/components/input.md) is named by its `FieldLabel` (`for` and `id`), and both
  are `required`, so the browser asks for them before the form submits.
- The password's "Forgot your password?" link sits in the label's row, after the label, so it
  comes after the label and before the input in the tab order, as upstream's.

## Testing

The block's test drives it with `CardHarness`, `FieldHarness`, `InputHarness` and
`ButtonHarness` (see its Test tab): its title, each field's label and input, and the form's
validity as the inputs fill in.

## Upstream

shadcn/ui's [`login-01`](https://ui.shadcn.com/blocks/login) block, from
`apps/v4/registry/bases/radix/blocks/login-01` at shadcn-ui/ui@8ab2771, in the Nova style.
