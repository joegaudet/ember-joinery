# Separator

Separates content, for assistive technology or only to the eye. It is ember-primitives'
`Separator` and Radix's: an `<hr>` by default, or any tag, with the separator role, its
orientation, and a decorative mode that assistive technology skips. It has no styles; the
styled [Separator](/components/separator.md) is built on it.

<Example @name="separator-headless" @title="A breadcrumb's slashes, and a rule" />

## Usage

```gts
import { Separator } from '@ember-joinery/primitives/separator'

<template>
  <Separator />
  <Separator @as="div" @orientation="vertical" />
  <ol>
    <li><a href="/">Home</a></li>
    <Separator @as="li" @decorative={{true}}>/</Separator>
    <li>Docs</li>
  </ol>
</template>
```

`separatorAria({ orientation, decorative, tag })` returns the ARIA and `data-orientation` the
component renders, for an element of your own.

## API

| Argument       | Type                         | Default        | What it does                                                |
| -------------- | ---------------------------- | -------------- | ----------------------------------------------------------- |
| `@as`          | tag name                     | `hr`           | The tag to render: `li` in a list, `span` in a line of text |
| `@decorative`  | `boolean`                    | `false`        | Whether assistive technology skips it, and what's inside it |
| `@orientation` | `"horizontal" \| "vertical"` | `"horizontal"` | Which way it runs                                           |
| `@name`        | `string`                     |                | Its name, for `SeparatorHarness` (`data-test-jn-name`)      |

A decorative separator other than an `<hr>` (which is void) yields its block, such as a
breadcrumb's `/`; a semantic one shows nothing, because a separator's content isn't read. It
takes attributes.

| Attribute          | Semantic                                      | Decorative |
| ------------------ | --------------------------------------------- | ---------- |
| `role`             | `separator` (none on an `<hr>`, which has it) | `none`     |
| `aria-orientation` | `vertical` when vertical                      |            |
| `aria-hidden`      |                                               | `true`     |
| `data-orientation` | `horizontal` or `vertical`                    | the same   |

## Accessibility

A semantic separator divides content a screen reader user hears as divided; a decorative one
only draws a line or a character, and isn't read. Radix marks a decorative separator
`role="none"`, ember-primitives `aria-hidden="true"`; Joinery does both, so content inside it,
such as a slash, is hidden too.

## Testing

```ts
import { SeparatorHarness } from '@ember-joinery/test-support'

const [slash] = SeparatorHarness.findAll()
slash.isDecorative // true
slash.orientation // 'horizontal'
slash.role // 'none'
```
