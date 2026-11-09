# Parity reference app

A private React 19 + Tailwind 4 app that renders [shadcn/ui](https://ui.shadcn.com/)'s own
examples, by id, the way its docs pages show them. `pnpm parity` screenshots each one next to the
matching Joinery example and compares them (see "Parity" in CONTRIBUTING.md).

It is its own pnpm workspace (`pnpm-workspace.yaml` here), so its dependencies stay out of the
main install. They are pinned to the versions in upstream's lockfile at the commit in
`upstream.json`, so Dependabot leaves them alone: a sync PR moves them along with that file.

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
