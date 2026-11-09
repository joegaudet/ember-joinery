# Breadcrumb

The path to the current page. It is ember-primitives' `Breadcrumb`: a `nav` named for
assistive technology, around an ordered list of crumbs, yielding a `Separator` that assistive
technology skips. It has no styles; the styled [Breadcrumb](/components/breadcrumb.md) has the
same anatomy, and its separator is this one.

<Example @name="breadcrumb-headless" @title="Home / Docs / Breadcrumb" />

## Usage

```gts
import { Breadcrumb } from '@ember-joinery/primitives/breadcrumb'

<template>
  <Breadcrumb as |b|>
    <li><a href="/">Home</a></li>
    <b.Separator>/</b.Separator>
    <li><a href="/docs">Docs</a></li>
    <b.Separator>/</b.Separator>
    <li aria-current="page">Breadcrumb</li>
  </Breadcrumb>
</template>
```

Mark the current page's crumb with `aria-current="page"`. `BreadcrumbSeparator`, the yielded
separator, is exported too, and `breadcrumbSeparatorAria()` returns its ARIA, for an element of
your own.

## API

| Argument | Type     | Default        | What it does                                            |
| -------- | -------- | -------------- | ------------------------------------------------------- |
| `@label` | `string` | `"Breadcrumb"` | What the navigation is called (`aria-label`)            |
| `@name`  | `string` |                | Its name, for `BreadcrumbHarness` (`data-test-jn-name`) |

It renders `<nav><ol>`, and takes attributes on the `nav`. It yields `b.Separator`: an `li`
(or `@as`) with `role="presentation"` and `aria-hidden="true"`, showing its block.

## Accessibility

The `nav` is a landmark with a name, so a screen reader user can jump to it, and the list tells
them how many crumbs there are. The separators are hidden, so only the crumbs are read.

## Testing

```ts
import { BreadcrumbHarness } from '@ember-joinery/test-support'

const path = new BreadcrumbHarness()
path.items // ['Home', 'Docs', 'Breadcrumb']
path.current // 'Breadcrumb'
await path.clickLink('Docs')
```

See the styled [Breadcrumb](/components/breadcrumb.md#testing) for every member.
