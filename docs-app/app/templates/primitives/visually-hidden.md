# Visually Hidden

Content that screen readers read and sighted users don't see, such as an icon button's label.
It is ember-primitives' and Radix's `VisuallyHidden`.

<Example @name="visually-hidden-icon-button" @title="An icon button's label" />

## Usage

```gts
import { VisuallyHidden, visuallyHidden } from '@ember-joinery/primitives/visually-hidden'

<template>
  <button type="button">
    <XIcon />
    <VisuallyHidden>Close</VisuallyHidden>
  </button>

  {{! or on any element, in place of ember-primitives' visually-hidden attribute }}
  <label for="search" {{visuallyHidden}}>Search</label>
</template>
```

The styles are Bootstrap's visually-hidden rules, applied inline, so the headless package needs
no style sheet. The modifier keeps the element's other inline styles, and puts back the ones it
replaced when it goes.

## API

| Argument | Type     | Default | What it does      |
| -------- | -------- | ------- | ----------------- |
| `@as`    | tag name | `span`  | The tag to render |

Its element has `data-slot="visually-hidden"` and takes attributes.

## Accessibility

Hidden text names the element around it, as `aria-label` would, and is translated with the
page. Use it when the visible design has no text.

## Testing

`VisuallyHidden` often wraps a part, such as a dialog's title, so it isn't a component root for
the harnesses: a part inside it still belongs to the component around it. Find its text through
the component's harness.
