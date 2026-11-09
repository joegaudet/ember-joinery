# Parity reference app

A private React 19 + Tailwind 4 app that renders [shadcn/ui](https://ui.shadcn.com/)'s own
examples, by id, in the style, direction and alignment their docs pages use. `pnpm parity`
screenshots each one next to the matching Joinery example and compares them (see "Parity" in
CONTRIBUTING.md).

It is its own pnpm workspace (`pnpm-workspace.yaml` here), so its dependencies stay out of the
main install. They are pinned to the versions in upstream's lockfile at the commit in
`upstream.json`, and a sync PR moves them along with that file. Dependabot doesn't touch them
because `.github/dependabot.yml` doesn't list `/parity`; keep it that way.

```bash
node scripts/upstream.mjs fetch    # upstream at the pinned commits, into .upstream/
pnpm --dir parity install
pnpm --dir parity start            # Vite prints its URL; / lists every example
```

`/<id>` renders one example, for instance `/button-demo`. Query parameters:

| Parameter | Values                                  | Default                      |
| --------- | --------------------------------------- | ---------------------------- |
| `theme`   | `light`, `dark`                         | `light`                      |
| `dir`     | `ltr`, `rtl`                            | what the docs page uses      |
| `align`   | `center`, `start`, `end`                | what the docs page uses      |
| `base`    | a base colour from `registry/themes.ts` | `neutral`, Joinery's default |

The ids are the docs pages' examples, the charts gallery and the blocks, as listed in
`upstream/inventory.json`. Each renders in the style its docs page uses (Nova for most, Rhea for
the chat set, Base UI's Nova for Combobox), inside a stage that matches the guide's
`/parity/<name>` route. When it has rendered and its fonts have loaded, `<html>` gets
`data-parity-ready`.

The stage is not the docs page's preview box. On ui.shadcn.com, a `<ComponentPreview>` can also
size and pad that box with `previewClassName` (`h-96 p-0`, or the Accordion page's
`*:data-[slot=accordion]:max-w-sm`), and style its frame with `className` (the chart demo's
`theme-blue`). The inventory records both for each example, for the guide's example frames, but
neither side of the comparison applies them: both stages are the same plain box, so the
screenshots compare the examples themselves. So an example can look narrower or taller on
ui.shadcn.com than it does here (the Accordion examples are 512px wide here and 384px there).

## How it builds upstream's examples

Upstream's examples import `@/styles/<base>-<style>/ui/*`, which shadcn's registry build
generates. `upstream-plugin.mjs` generates the same files into `.generated/styles/`, with the same
transforms from the published `shadcn` package (inlining each style sheet's classes, swapping
icon placeholders for lucide icons, and making the right-to-left copies). Upstream's own scripts
are never run. The plugin also maps `@/` to upstream's `apps/v4`, `@shadcn/react` and
`@shadcn/helpers` to their upstream sources, and Next.js modules to the small stand-ins in
`src/shims/`. The page's CSS is upstream's own `globals.css`, with the theme tokens replaced by
the base colour's.

## The map

`map/<component>.json` maps the upstream examples on one docs page to Joinery's guide examples.
See `map/README.md`.

## Browser and fonts

`pnpm parity` runs playwright-core's own Chromium build: CI installs it with
`pnpm exec playwright-core install --with-deps chromium`. Locally, Playwright finds it under
`PLAYWRIGHT_BROWSERS_PATH` (cloud dev containers often have one in `/opt/pw-browsers`) only while
that folder holds the build for the installed playwright-core version. After a playwright-core
upgrade, run `pnpm exec playwright-core install chromium` again. `PARITY_CHROMIUM=/path/to/chrome`
runs another Chromium binary instead, but its screenshots won't match CI's, so use it only to
look at a comparison, never to set a threshold. Dependabot opens playwright-core upgrades as
their own PR, outside the weekly group, because a new Chromium can move every screenshot.

Both pages get the same fonts, Geist, Geist Mono and Noto Sans Arabic and Hebrew, from this
app's `@fontsource-variable` packages. `scripts/parity.mjs` serves them from a server of its own
on every run, so they load even when `--reference-url` or `--joinery-url` points at other servers.
A font that doesn't load is an error, never a silent fallback. This app also loads them before
it renders an example, as ui.shadcn.com preloads Geist: a Radix part that measures itself on
mount (the collapsible and accordion content pin their height) would otherwise keep the line
breaks of whatever fallback font the machine has.
