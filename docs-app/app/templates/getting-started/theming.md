# Theming

Using CSS variables and theme tokens.

<div class="callout">

**Want to build your theme visually?** The [Theme Builder](/getting-started/theme-builder.md)
shows every component in the style, base colour, radius and tokens you pick, then gives you the
CSS.

</div>

Joinery's look comes from shadcn/ui's: the same tokens, the same eight
[styles](/getting-started/styles.md) and the same base colours, ported from upstream at the
commit the guide is built from. Every example on these pages has switchers above it: pick a
style, a base colour, a radius, light or dark, right to left, or a phone's width, and see it
there.

The tokens are CSS variables with shadcn's names: semantic tokens such as `--background`,
`--foreground` and `--primary` that every component uses. Override them in your CSS to change
the look of your app without touching a component.

## Token convention

The tokens come in background and foreground pairs. The base token is a surface's colour, and
its `-foreground` token the colour of the text and icons on it: `--primary` pairs with
`--primary-foreground`.

```css
:root {
  --primary: oklch(0.205 0 0);
  --primary-foreground: oklch(0.985 0 0);
}
```

A default [Button](/components/button.md) is `--primary` with `--primary-foreground` text.

## Theme tokens

These tokens live in your CSS, light on `:root` and dark on `.dark`.

| Token                                                | What it controls                                       | Used by                                                                      |
| ---------------------------------------------------- | ------------------------------------------------------ | ---------------------------------------------------------------------------- |
| `--background` / `--foreground`                      | The default app background and text color.             | The page shell, page sections, and default text.                             |
| `--card` / `--card-foreground`                       | Elevated surfaces and the content inside them.         | `Card`, dashboard panels, settings panels.                                   |
| `--popover` / `--popover-foreground`                 | Floating surfaces and the content inside them.         | `Popover`, `DropdownMenu`, `ContextMenu`, and other overlays.                |
| `--primary` / `--primary-foreground`                 | High-emphasis actions and brand surfaces.              | Default `Button`, selected states, badges, and active accents.               |
| `--secondary` / `--secondary-foreground`             | Lower-emphasis filled actions and supporting surfaces. | Secondary buttons, secondary badges, and supporting UI.                      |
| `--muted` / `--muted-foreground`                     | Subtle surfaces and lower-emphasis content.            | Descriptions, placeholders, empty states, helper text, and subdued surfaces. |
| `--accent` / `--accent-foreground`                   | Interactive hover, focus, and active surfaces.         | Ghost buttons, menu highlight states, hovered rows, and selected items.      |
| `--destructive`                                      | Destructive actions and error emphasis.                | Destructive buttons, invalid states, and destructive menu items.             |
| `--border`                                           | Default borders and separators.                        | Cards, menus, tables, separators, and layout dividers.                       |
| `--input`                                            | Form control borders and input surface treatment.      | `Input`, `Textarea`, `Select`, and outline-style controls.                   |
| `--ring`                                             | Focus rings and outlines.                              | Buttons, inputs, checkboxes, menus, and other focusable controls.            |
| `--chart-1` … `--chart-5`                            | The default chart palette.                             | Charts and chart-driven dashboard blocks.                                    |
| `--sidebar` / `--sidebar-foreground`                 | The base sidebar surface and default sidebar text.     | The `Sidebar` container and its default content.                             |
| `--sidebar-primary` / `--sidebar-primary-foreground` | High-emphasis actions inside the sidebar.              | Active items, icon tiles, badges, and sidebar CTAs.                          |
| `--sidebar-accent` / `--sidebar-accent-foreground`   | Hover and selected states inside the sidebar.          | Sidebar menu hover states, open items, and interactive rows.                 |
| `--sidebar-border`                                   | Sidebar-specific borders and separators.               | Sidebar headers, groups, and internal dividers.                              |
| `--sidebar-ring`                                     | Sidebar-specific focus rings.                          | Focused controls inside the sidebar.                                         |
| `--radius`                                           | The base corner radius scale.                          | Cards, inputs, buttons, popovers, and the derived `--radius-*` tokens.       |

The chart tokens are covered in more detail on the [Chart](/components/chart.md#theming) page.

`tokens.css` is the default theme, the Neutral base colour, light and dark:

```ts
import '@ember-joinery/ember/tokens.css'
import '@ember-joinery/ember/joinery.css'
```

Because the names are shadcn's, a theme from [ui.shadcn.com](https://ui.shadcn.com/create)
pastes in unchanged: put its `:root` and `.dark` blocks in your own CSS, after `tokens.css` or
in place of it. Your CSS wins over Joinery's, which sits in the `joinery` cascade layer.

## Tokens cascade

The tokens are custom properties, so they cascade: set some on an element, and every component
inside it takes them. A part of the page can have its own theme without a line of component
code:

<Example @name="theming-scoped-tokens" @title="Tokens set on one card" />

## Radius scale

`--radius` is the base radius token for your theme. A small scale derives from it, so components
can use consistent corner sizes while still sharing one source of truth:

```css
:root {
  --radius-sm: calc(var(--radius) * 0.6);
  --radius-md: calc(var(--radius) * 0.8);
  --radius-lg: var(--radius);
  --radius-xl: calc(var(--radius) * 1.4);
  --radius-2xl: calc(var(--radius) * 1.8);
  --radius-3xl: calc(var(--radius) * 2.2);
  --radius-4xl: calc(var(--radius) * 2.6);
}
```

`--radius-lg` is the base value; the smaller radii scale down from it and the larger ones up,
so changing `--radius` updates the whole scale. `joinery.css` sets the scale for you (in a
Tailwind app, `tailwind.css` maps it to `rounded-*`).

## Adding tokens

To add a token, define it under `:root` and `.dark`:

```css
:root {
  --warning: oklch(0.84 0.16 84);
  --warning-foreground: oklch(0.28 0.07 46);
}

.dark {
  --warning: oklch(0.41 0.11 46);
  --warning-foreground: oklch(0.99 0.02 95);
}
```

Use it in your CSS as `var(--warning)`. In a Tailwind app, expose it to Tailwind with
`@theme inline`, and `bg-warning` and `text-warning-foreground` work:

```css
@theme inline {
  --color-warning: var(--warning);
  --color-warning-foreground: var(--warning-foreground);
}
```

## Base colors

shadcn's base colours each set every token, light and dark. The available base colours are
**Neutral**, **Stone**, **Zinc**, **Mauve**, **Olive**, **Mist** and **Taupe**. Import one in
place of `tokens.css`:

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

## Styles and dark mode

A style changes how the components look (their spacing, radii, borders and shadows), not their
colours: see [Styles](/getting-started/styles.md). Each token has a dark value on `.dark`; see
[Dark mode](/getting-started/dark-mode.md) for turning it on.

## Tailwind

Joinery's CSS is compiled, so apps don't need Tailwind. In a Tailwind app, `tailwind.css` maps
the tokens to Tailwind's theme, so `bg-primary`, `text-muted-foreground` and `rounded-lg`
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

## Upstream

shadcn/ui's [Theming](https://ui.shadcn.com/docs/theming) page, from
`apps/v4/content/docs/(root)/theming.mdx` at shadcn-ui/ui@8ab2771, in Joinery's terms: no
`components.json`, and the CSS ships compiled.
