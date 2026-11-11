# Installation

How to install and set up Joinery in your app.

Joinery works with Ember 6.12 LTS and 7, in Vite (Embroider) apps and classic ember-cli apps,
with or without Tailwind. Its packages are v2 addons: import what you use into `.gjs` and
`.gts` files. Each kind of app has an example in the repository's
[`examples/`](https://github.com/joegaudet/ember-joinery/tree/main/examples) folder, and CI
builds and tests every one of them.

<div class="callout">

**Not on npm yet.** Joinery publishes once its first release is reviewed. Until then, these are
the steps the example apps follow inside the repository.

</div>

## Vite apps

Add the packages:

```bash
pnpm add @ember-joinery/ember
pnpm add --save-dev @ember-joinery/test-support
```

Then import Joinery's CSS once, in `app/app.ts`: the theme's tokens, then the components:

```ts
import '@ember-joinery/ember/tokens.css'
import '@ember-joinery/ember/joinery.css'
```

The rules sit in the `joinery` cascade layer, so your own CSS always wins over them.
[Theming](/getting-started/theming.md) has the other base colours,
[Styles](/getting-started/styles.md) the other seven styles, and the
[Theme Builder](/getting-started/theme-builder.md) makes a theme of your own.

The examples import icons from [`lucide`](https://lucide.dev/), as shadcn's do, one at a time:

```bash
pnpm add lucide
```

Now use a component:

```gts
import { Button, Icon } from '@ember-joinery/ember'
import { ArrowUpRight } from 'lucide'

<template>
  <Button @variant="outline">
    Open
    <Icon @icon={{ArrowUpRight}} data-icon="inline-end" />
  </Button>
</template>
```

## Classic apps

Classic ember-cli apps consume v2 addons through
[ember-auto-import](https://github.com/embroider-build/ember-auto-import), version 2 or later,
and need [ember-template-imports](https://github.com/ember-template-imports/ember-template-imports)
for `.gjs` and `.gts` files:

```bash
pnpm add --save-dev ember-auto-import ember-template-imports @ember-joinery/ember @ember-joinery/test-support
```

Import the CSS (`tokens.css`, then `joinery.css`) from `app/app.js` as in a Vite app.
ember-auto-import bundles it, along with the components you import into your `.gjs` and `.gts`
files.

## Tailwind apps

Joinery doesn't need Tailwind, but it works alongside it. Import `tokens.css` and
`joinery.css` as above, and start your Tailwind entry point by placing Joinery's layer between
Tailwind's `base` and `components`, then add Joinery's `tailwind.css`, which maps the tokens to
Tailwind's theme (`bg-primary`, `rounded-lg`) and adds the `dark:` variant:

```css
/* Layers declared first lose. */
@layer theme, base, joinery, components, utilities;
@import 'tailwindcss';
@import '@ember-joinery/ember/tailwind.css';
```

Tailwind's preflight lives in `base`, and it resets every button, input and margin. With
Joinery's layer above it, those resets don't undo Joinery's padding, borders and backgrounds.
With Tailwind's utilities above Joinery's layer, a `class="…"` on a component overrides its
own styles. The `@layer` line has to come before any other style sheet declares a layer, so
import this entry point before `joinery.css`.

## The opt-in add-ons

Components on a heavy library are packages of their own, so an app that doesn't use them never
installs the library. Each takes `@ember-joinery/ember` as a peer, and has its harnesses at its
own `/test-support`:

| Package                         | What it adds                                                         | Install                                                      |
| ------------------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------ |
| `@ember-joinery/chart`          | [Charts](/components/chart.md), on d3                                | `pnpm add @ember-joinery/chart`                              |
| `@ember-joinery/carousel`       | [Carousel](/components/carousel.md), on Embla                        | `pnpm add @ember-joinery/carousel`                           |
| `@ember-joinery/data-table`     | [Data Table](/components/data-table.md), on TanStack Table           | `pnpm add @ember-joinery/data-table`                         |
| `@ember-joinery/code-block`     | [Code Block](/components/code-block.md), on Shiki                    | `pnpm add @ember-joinery/code-block`                         |
| `@ember-joinery/file-upload`    | [File Upload](/components/file-upload.md), on ember-file-upload      | `pnpm add @ember-joinery/file-upload tracked-built-ins`      |
| `@ember-joinery/tiptap`         | [Rich Text Editor](/components/rich-text-editor.md), on Tiptap       | `pnpm add @ember-joinery/tiptap @tiptap/core @tiptap/pm`     |
| `@ember-joinery/power-calendar` | [Power Calendar](/components/power-calendar.md) and its date pickers | `pnpm add @ember-joinery/power-calendar ember-concurrency`   |
| `@ember-joinery/maskito`        | [Masked Input](/components/masked-input.md) and Phone Input          | `pnpm add @ember-joinery/maskito`                            |
| `@ember-joinery/formwright`     | Joinery's inputs as [Formwright](/formwright/index.md) controls      | `pnpm add @ember-joinery/formwright @ember-formwright/ember` |

Their CSS is in `joinery.css` already: nothing more to import.

## TypeScript and Glint

The packages ship their type declarations, and every component has a Glint signature: its
arguments, blocks and element are checked in your `.gts` templates with no registry to add.
The [API reference](/reference/index.md) lists them, package by package.

## Testing

`@ember-joinery/test-support` has a harness for every component. Write your tests with them,
and end each with an axe audit: see [Testing](/getting-started/testing.md).
