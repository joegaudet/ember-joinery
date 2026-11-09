# ExternalLink

The `<ExternalLink />` component is a light wrapper around the [anchor
element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/a), which will always make
your link an external link. It is ember-primitives' `ExternalLink`.

Unlike `<Link />`, `<ExternalLink />` uses the native `href` attribute.

This component always has `target=_blank` and `rel='noreferrer noopener'`.

<Example @name="external-link-demo" @title="A link to MDN" />

## Usage

```gts
import { ExternalLink } from '@ember-joinery/primitives/external-link'

<template>
  <ExternalLink href="https://developer.mozilla.org">MDN</ExternalLink>
</template>
```

Without an `href`, its `href` is `##missing##`, so a link that lost its address shows it.
Your own `target` or `rel` replaces its own. [`Link`](/primitives/link.md) renders one for an
`@href` on another site.

## API

| Argument | Type     | What it does              |
| -------- | -------- | ------------------------- |
| `@name`  | `string` | Its name, for its harness |

Attributes, `href` among them, go on the `<a>`.

## Accessibility

A new tab can surprise: say in the link's text, or with an icon that has a label, that it
opens one.

## Testing

`ExternalLinkHarness` is a [`LinkHarness`](/primitives/link.md#testing) for external links
only.

```ts
import { ExternalLinkHarness } from '@ember-joinery/test-support'

const mdn = new ExternalLinkHarness()
mdn.href // 'https://developer.mozilla.org'
mdn.opensInNewTab // true
mdn.isIsolated // true
```
