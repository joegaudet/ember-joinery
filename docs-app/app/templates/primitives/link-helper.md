# Link Helper

`(link href)` says what an app needs to know about a link to render it: whether it leaves the
app (`isExternal`), whether it is the current route (`isActive`, for an active style or
`aria-current`), and a click handler that routes it (`handleClick`). A design system's own
`Link` builds on it. It is ember-primitives' `link` helper.

<Example @name="link-helper-nav" @title="A nav that knows where you are" />

## Usage

```gts
import { on } from '@ember/modifier'
import { link } from '@ember-joinery/primitives/link'

<template>
  {{#let (link "/settings" activeOnSubPaths=true) as |l|}}
    <a
      href="/settings"
      aria-current={{if l.isActive "page"}}
      target={{if l.isExternal "_blank"}}
      {{on "click" l.handleClick}}
    >Settings</a>
  {{/let}}
</template>
```

The `href` is the full path, with the app's `rootURL` (the router service has it as
`rootURL`). `isActive` is reactive, and never true for an external link or one outside the
`rootURL`. `handleClick` turns a click on a link to one of the app's routes into a transition,
leaving the rest to the browser, as [`properLinks`](/primitives/proper-links.md) does for every
link; with `properLinks` on the router, it isn't needed.

## API

| Named argument             | Type                  | Default | What it does                                                        |
| -------------------------- | --------------------- | ------- | ------------------------------------------------------------------- |
| `includeActiveQueryParams` | `boolean \| string[]` | `false` | Whether query params count towards `isActive`: all, or these        |
| `activeOnSubPaths`         | `boolean`             | `false` | Whether the routes below count too (`/forum/1` on `/forum/1/posts`) |

| Yielded       | What it is                                               |
| ------------- | -------------------------------------------------------- |
| `isExternal`  | Whether the link goes to another origin                  |
| `isActive`    | Whether the link is the current route                    |
| `handleClick` | A click handler that routes a click on a link to the app |

The module also exports `isExternal(href)`, `isActive(router, href, queryParams?, subPaths?)`
and `dynamicSegments(routeInfo)`, for use in JavaScript.

### From ember-primitives

The same helper. Joinery's `isActive` also handles the app's `rootURL` when query params count,
and with `includeActiveQueryParams=true` the link's own params must match too, not only the
current URL's.

## Testing

`setupRouting` from `@ember-joinery/test-support` gives a test its own routes (see
[Proper Links](/primitives/proper-links.md#testing)); then `visit()` and click as a user would.
