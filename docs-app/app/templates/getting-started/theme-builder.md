# Theme Builder

Pick a style and a base colour, set the radius, and edit any of shadcn's tokens, light and
dark: every component below follows as you type. Then copy the CSS into your app. It is the
guide's counterpart to [ui.shadcn.com/create](https://ui.shadcn.com/create), for the eight
styles and seven base colours Joinery ships.

<ThemeBuilder />

## Using your theme

The CSS has every token, light on `:root` and dark on `.dark`, as shadcn's own themes do, so it
takes the place of `tokens.css`. Save it in your app, say as `app/styles/theme.css`, and import
it with the style's sheet:

```ts
// app/app.ts
import './styles/theme.css'
import '@ember-joinery/ember/styles/lyra.css' // or joinery.css, for Nova
```

Joinery's rules are in the `joinery` cascade layer, and your theme isn't, so its tokens win
wherever it is imported. [Theming](/getting-started/theming.md) explains each token, and
[Styles](/getting-started/styles.md) what each style changes. A token you add yourself, such as
a `--warning`, goes in the same blocks: see
[Adding tokens](/getting-started/theming.md#adding-tokens).

## What the builder shows

Every component page's first example, in the style, base colour, radius and tokens you pick.
Overlays (dialogs, menus, popovers, toasts) open in the theme too. A colour picked with a
swatch is written as `oklch(…)`, the form shadcn's tokens take; the swatch itself shows the
nearest colour your screen can, and no transparency, so a token such as the dark `--border`
(`oklch(1 0 0 / 10%)`) is best edited as text.
