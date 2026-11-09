# Theming

Joinery's look comes from shadcn/ui's: the same tokens, the same eight styles and the same base
colours, ported from upstream at the commit the guide is built from. Every example on these
pages has switchers above it: pick a style, a base colour, a radius, light or dark, right to
left, or a phone's width, and see it there.

## Tokens

The colours, the radius and the chart and sidebar colours are CSS custom properties, under
shadcn's own names: `--background`, `--foreground`, `--primary`, `--ring`, `--radius`,
`--chart-1` to `--chart-5`, `--sidebar-*` and the rest. The values are OKLCH, light on `:root`
and dark on `.dark`. `tokens.css` is the default theme, the Neutral base colour:

```ts
import '@ember-joinery/ember/tokens.css'
import '@ember-joinery/ember/joinery.css'
```

Because the names are shadcn's, a theme from [ui.shadcn.com](https://ui.shadcn.com/create)
pastes in unchanged: put its `:root` and `.dark` blocks in your own CSS, after `tokens.css` or
in place of it. Your CSS wins over Joinery's, which sits in the `joinery` cascade layer.

```css
:root {
  --radius: 0.5rem;
  --primary: oklch(0.488 0.243 264.376);
  --primary-foreground: oklch(0.97 0.014 254.604);
}
```

`--radius` is the base of a scale (`--radius-sm` is 0.6 of it, `--radius-xl` 1.4, and so on),
which the components read, so one value rounds everything.

## Base colours

shadcn's base colours each set every token, light and dark. Import one in place of
`tokens.css`:

```ts
import '@ember-joinery/ember/themes/stone.css'
```

| Base colour | File                                     |
| ----------- | ---------------------------------------- |
| Neutral     | `themes/neutral.css` (also `tokens.css`) |
| Stone       | `themes/stone.css`                       |
| Zinc        | `themes/zinc.css`                        |
| Mauve       | `themes/mauve.css`                       |
| Olive       | `themes/olive.css`                       |
| Mist        | `themes/mist.css`                        |
| Taupe       | `themes/taupe.css`                       |

## Styles

shadcn/ui now ships eight styles, each a different take on the same components: spacing,
radii, borders, shadows. Nova is shadcn's default, and `joinery.css` is Nova. The other seven
are in `styles/`; import one in place of `joinery.css`:

```ts
import '@ember-joinery/ember/tokens.css'
import '@ember-joinery/ember/styles/lyra.css'
```

The styles are Luma, Lyra, Maia, Mira, Nova, Rhea, Sera and Vega. Each style sheet holds every
component, so import exactly one.

## Dark mode

Put the `dark` class on `<html>` (or any element, for the part of the page inside it), as
shadcn does. `@ember-joinery/primitives/color-scheme` follows the system, remembers the
user's choice and keeps tabs in sync; see [Color Scheme](/primitives/color-scheme.md).

## Tailwind

Joinery's CSS is compiled, so apps don't need Tailwind. In a Tailwind app, `tailwind.css`
maps the tokens to Tailwind's theme, so `bg-primary`, `text-muted-foreground` and `rounded-lg`
follow your theme, and adds shadcn's `dark:` variant:

```css
@layer theme, base, joinery, components, utilities;
@import 'tailwindcss';
@import '@ember-joinery/ember/tailwind.css';
```

With Joinery's layer below `components` and `utilities`, a class on a component overrides its
style, as `rounded-full` does on a [Button](/components/button.md).

## Without Tailwind

Upstream's components rely on Tailwind's preflight (every element sizes from its border edge,
buttons take the page's font, links lose their underline). Joinery's CSS gives its parts the
same, and only its parts: anything with a `data-slot`, and what's inside it. The rest of your
page is left as it is.
