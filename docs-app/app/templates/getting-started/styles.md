# Styles

shadcn/ui now ships eight styles, each a different take on the same components: their spacing,
radii, borders, shadows and type. Joinery ports all eight. Nova is shadcn's default, and
`joinery.css` is Nova.

Every example in this guide has a **Style** switcher above it. Try it here:

<Example @name="card-demo" @title="One card, in any style" />

## The eight styles

| Style | What it is, in upstream's words | Import                                 |
| ----- | ------------------------------- | -------------------------------------- |
| Vega  | Clean, neutral, and familiar    | `@ember-joinery/ember/styles/vega.css` |
| Nova  | Reduced padding and margins     | `@ember-joinery/ember/joinery.css`     |
| Maia  | Rounded, with generous spacing  | `@ember-joinery/ember/styles/maia.css` |
| Lyra  | Boxy and sharp. For mono fonts  | `@ember-joinery/ember/styles/lyra.css` |
| Mira  | Made for compact interfaces     | `@ember-joinery/ember/styles/mira.css` |
| Luma  | Fluid, luminous, and soft       | `@ember-joinery/ember/styles/luma.css` |
| Sera  | Editorial and typographic       | `@ember-joinery/ember/styles/sera.css` |
| Rhea  | Like Luma but compact           | `@ember-joinery/ember/styles/rhea.css` |

## Using a style

Each style sheet styles every component, so import exactly one, after the tokens:

```ts
// app/app.ts
import '@ember-joinery/ember/tokens.css'
import '@ember-joinery/ember/styles/lyra.css' // in place of joinery.css
```

A style changes how the components look, not their colours: those are the theme's
[tokens](/getting-started/theming.md), and any base colour works with any style. The
[Theme Builder](/getting-started/theme-builder.md) shows every component in the style and
colours you pick.

## How the styles are made

Upstream's components carry semantic classes (`cn-button`, `cn-button-variant-outline`) that
each of its style sheets (`registry/styles/style-<name>.css`) defines with Tailwind's `@apply`.
Joinery's components render the same classes, renamed `jn-` (`jn-button
jn-button-variant-outline`), and its build ports the sheets mechanically and compiles them with
Tailwind into plain CSS. So the styles are upstream's, rule for rule, and an app needs no
Tailwind to use them.

Every rule is in the `joinery` cascade layer and inside `:where()`, so your own CSS always wins:

```css
.jn-button {
  border-radius: 9999px;
}
```

In a Tailwind app, a class on a component does the same: `<Button class="rounded-full">`.

## Upstream

shadcn/ui's styles are picked at [ui.shadcn.com/create](https://ui.shadcn.com/create); their
names and descriptions are from `apps/v4/registry/styles.tsx`, and their sheets from
`apps/v4/registry/styles/`, at shadcn-ui/ui@8ab2771.
