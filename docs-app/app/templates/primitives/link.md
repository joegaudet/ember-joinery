# Link

A light wrapper around the [anchor element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/a),
which will appropriately make your link an external link if the passed `@href` is not on the
same domain. It is ember-primitives' `Link`.

Most of the time, for in-app navigations especially, you'll want to use the native `<a>`
element. However, for consistent usage and behavior within a design system, it'll be beneficial
to lint against `<a>`, and use a design-system-provided version of `<Link />`, which wraps
_this_ `<Link />`.

The `<Link />` component provides additional behavior and utilities for styling and providing
additional context, such as within `<nav>` or other UI patterns which persist across multiple
page navigations.

`<Link />` will automatically externalize a `href` which specify different domains (add
`target='_blank'` and `rel='noreferrer noopener'`).

<Example @name="link-demo" @title="An internal and an external link" />

## Features

- Full keyboard navigation
- Active state
- "Just an `<a>`"

## Usage

```gts
import { Link } from '@ember-joinery/primitives/link'

<template>
  <Link @href="..." as |a|>
    {{if a.isActive "active!"}}
    {{if a.isExternal "external!"}}
  </Link>
</template>
```

A click on a link to one of the app's routes is a transition, so `<Link>` works without
[`properLinks`](/primitives/proper-links.md); with it, nothing changes. The `@href` is the full
path, with the app's `rootURL`. The active state comes from the
[link helper](/primitives/link-helper.md), which you can use to write a link of your own.

## API

| Argument                    | Type               | What it does                                                        |
| --------------------------- | ------------------ | ------------------------------------------------------------------- |
| `@href`                     | `string`           | Where it goes: a path with the `rootURL`, or a URL                  |
| `@includeActiveQueryParams` | `true \| string[]` | Whether query params count towards the active state: all, or these  |
| `@activeOnSubPaths`         | `true`             | Whether it is active on the routes below its own (`/forum/1/posts`) |
| `@name`                     | `string`           | Its name, for its harness                                           |

With `@includeActiveQueryParams={{true}}`, the link is active only where every query param
matches its own; with a list, only those params count. With `@activeOnSubPaths`, `/forum/1` is
active on `/forum/1`, `/forum/1/posts` and anything else below it; without it, on `/forum/1`
alone.

| Yielded      | What it is                                                                         |
| ------------ | ---------------------------------------------------------------------------------- |
| `isExternal` | Whether `@href` is on another site, for telling the user they are about to leave   |
| `isActive`   | Whether `@href` is the current page (see the arguments). Never for an external one |

### State Attributes

| Attribute      | When                                                                                |
| -------------- | ----------------------------------------------------------------------------------- |
| `data-active`  | `"true"` when `@href` is the current URL; absent otherwise                          |
| `aria-current` | `page` on the current route; `true` on a link active below it (`@activeOnSubPaths`) |

<Example @name="link-active" @title="Styling the active link" />

### From ember-primitives

The same component, on Joinery's [link helper](/primitives/link-helper.md), so an `@href`
with the app's `rootURL` is active when query params count too, and with
`@includeActiveQueryParams={{true}}` its own params must match as well (see the helper's
notes).

## Accessibility

The current page's link has `aria-current="page"`, which screen readers announce; a link
active on the routes below its own has `aria-current="true"`, as it isn't the page itself. An
external link opens a new tab: say so, with text or an icon that has a label, as `isExternal`
lets you.

## Testing

`LinkHarness` drives a `<Link>`, internal or external. In a test, `setupRouting` gives the app
its routes (see [Proper Links](/primitives/proper-links.md#testing)).

```ts
import { LinkHarness } from '@ember-joinery/test-support'

const forum = new LinkHarness('forum') // <Link @name="forum">
forum.href
forum.text
forum.isCurrent // from aria-current; current is its value: 'page', 'true' or null
forum.opensInNewTab // an external one does
forum.isIsolated // rel has noopener and noreferrer
await forum.follow()
```
