# Signup

A simple signup form.

<Example @name="signup-01" @title="signup-01" @block={{true}} @blockHeight={{930}} />

## Installation

Blocks aren't exported from a package: copy the block's files into your app. It uses
`@ember-joinery/ember`:

```bash
pnpm add @ember-joinery/ember
```

and Tailwind's utilities for its layout, as upstream's does: see
[Installation](/getting-started/installation.md) for a Tailwind app.

## Files

| File                        | What it is                                                                                                       |
| --------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `signup-01.gts`             | The page: the form, centred, no wider than `max-w-sm`                                                            |
| `signup-01/signup-form.gts` | `SignupForm`: a [Card](/components/card.md) around four described [Fields](/components/field.md) and the buttons |

`SignupForm` puts your attributes on its Card, as upstream's spreads its props there.

## Accessibility

- Each [Input](/components/input.md) is named by its `FieldLabel` and described by the
  `FieldDescription` under it, and every one is `required`.

## Testing

The block's test drives it with `CardHarness`, `FieldGroupHarness`, `FieldHarness`,
`InputHarness` and `ButtonHarness` (see its Test tab).

## Upstream

shadcn/ui's [`signup-01`](https://ui.shadcn.com/blocks/signup) block, from
`apps/v4/registry/bases/radix/blocks/signup-01` at shadcn-ui/ui@8ab2771, in the Nova style.
