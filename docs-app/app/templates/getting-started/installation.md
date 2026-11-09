# Installation

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
[Theming](/getting-started/theming.md) has the other base colours and styles, and how to paste
in a theme from ui.shadcn.com.

The examples import icons from [`lucide`](https://lucide.dev/), as shadcn's do, one at a time:

```bash
pnpm add lucide
```

## Classic apps

Classic ember-cli apps consume v2 addons through
[ember-auto-import](https://github.com/embroider-build/ember-auto-import), version 2 or later:

```bash
pnpm add --save-dev ember-auto-import @ember-joinery/ember @ember-joinery/test-support
```

Import the CSS (`tokens.css`, then `joinery.css`) from `app/app.js` as in a Vite app. ember-auto-import bundles it, along with the
components you import into your `.gjs` and `.gts` files.

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
