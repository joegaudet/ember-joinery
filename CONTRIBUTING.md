# Contributing

> **Phase 0.** This guide describes how the repo works once Phase 1 adds the tooling (see
> [JOINERY_PLAN.md](JOINERY_PLAN.md)). Commands marked † don't exist yet.

## Setup

```bash
pnpm install   # †
pnpm build     # † the test app, guide and examples import the packages' built output
pnpm start     # † the demo (test-app); Vite prints its URL
```

pnpm runs scripts on Node 24 (`useNodeVersion` in `pnpm-workspace.yaml`).

## The gate

CI runs exactly these; run them before opening a PR.

```bash
pnpm format:check                  # †
pnpm build                         # †
pnpm lint                          # †
pnpm typecheck                     # †
node --test scripts/*.test.mjs     # †
pnpm test                          # † test-app, Ember 7.3
pnpm --filter docs-app test        # † every guide example and page
pnpm test:examples                 # † vite-basic, classic, tailwind, formwright
pnpm parity                        # † screenshot comparison with shadcn/ui
```

CI also runs the suite on the previous LTS (6.12) by overriding `ember-source` for the whole
workspace. To do that locally, add `ember-source: ~6.12.0` under `overrides:` in
`pnpm-workspace.yaml`, then run `pnpm install --no-frozen-lockfile && pnpm build && pnpm test`,
and revert both files afterwards. Overriding only the test app loads two copies of Ember.

CI also runs the suite once more with CSS anchor positioning turned off, so the Floating UI
fallback is tested too.

## Porting a component

Joinery copies [ui.shadcn.com](https://ui.shadcn.com/). Port from the upstream source at the
commits pinned in `upstream.json`, never from memory:

1. Read the component's source, `apps/v4/registry/new-york-v4/ui/<name>.tsx` in shadcn-ui/ui,
   its docs page, `apps/v4/content/docs/components/radix/<name>.mdx`, and every example for it
   in `apps/v4/registry/new-york-v4/examples/`. If ember-primitives has the component, read it in
   `ember-primitives/src/components/` too.
2. Put the behaviour in `@ember-joinery/primitives`, the styled component in
   `@ember-joinery/ember`, and the harness in `@ember-joinery/test-support`.
3. Seed its CSS with `scripts/extract-classes.mjs` (†), which pulls shadcn's class strings out
   of the upstream `cn(...)` and `cva(...)` calls.

A component is done when it has everything listed under "Definition of done for every
component" in the plan: its primitive, the styled component, its harness, tests written with the
harness (including the keyboard pattern, controlled and uncontrolled state, RTL and an axe audit),
a guide page with every upstream example, a parity mapping for each example, and a changeset.

## Tests first

Behaviour changes start with a failing test in `test-app/tests/`. Write tests with harness
classes, not raw selectors. A new component gets a harness class; page objects are harness
subclasses with `@child` declarations. Every test ends in an axe audit.

## Parity

`pnpm parity` (†) renders each upstream example in the React reference app (`parity/`) and the
matching Ember example in the guide's `/parity/<id>` route, then compares screenshots in light
and dark. `parity/map.json` maps upstream example ids to Joinery examples. An unmapped upstream
example fails the check. So does a diff over the threshold, unless the map gives that example its
own threshold along with a written reason.

## Upstream sync

`node scripts/upstream.mjs` (†) lists what changed upstream since the commits in `upstream.json`,
mapped to Joinery components. A weekly workflow keeps a tracking issue up to date. A sync PR
ports the changes and moves `upstream.json` forward in the same PR. Nothing else changes that
file.

## Changesets

Every change to a published package needs a changeset (`pnpm changeset`). The packages version
together.

## Releasing

A release is cut by pushing a tag. Nothing publishes on merge.

1. PRs that change a published package carry a changeset. While any are pending on `main`, CI
   keeps a "chore: version packages" PR open with the next version and the changelogs.
2. Merge that PR.
3. Tag the merge commit with the new version and push the tag:

   ```bash
   git switch main && git pull
   git tag -a v0.1.0 -m v0.1.0
   git push origin v0.1.0
   ```

`release.yml` checks that the tag is on `main` and matches every public package's version. It
publishes whatever isn't already on npm through `scripts/publish.mjs` (OIDC trusted publishing
with provenance; there is no `NPM_TOKEN`), then creates the GitHub release. If a run fails,
re-run it: it skips what is already published.

**A brand-new package** can't publish through OIDC, because npm only configures a trusted
publisher for a name that already exists. Its first release goes out once through
`bootstrap-publish.yml`, behind the `npm-bootstrap` environment, using a short-lived `NPM_TOKEN`
environment secret (the file's header has the steps). After that, set
`joegaudet/ember-joinery` / `release.yml` as the package's trusted publisher on npmjs.com.

The version PR is opened by a GitHub App, not `GITHUB_TOKEN`: GitHub runs no workflows for
pushes made with `GITHUB_TOKEN`, so the PR would never get its required checks. The App's client
ID is the repository variable `RELEASE_APP_CLIENT_ID`, and its private key is the secret
`RELEASE_APP_PRIVATE_KEY`. Until both are set, the version job is skipped, and the release script
opens the version PR as the person releasing.

## The guide

`docs-app/` (†) is the guide at `/ember-joinery/guide/`, built with
[Kolay](https://github.com/universal-ember/kolay). `pnpm guide:start` serves it locally.

- There is one page per component, `docs-app/app/templates/components/<name>.md`, laid out like
  its ui.shadcn.com page. `meta.json` files set the order. Add each new page to `PAGES` in
  `docs-app/tests/acceptance/pages-test.ts`.
- Examples are `.gts` files in `docs-app/app/examples/`, one per upstream example, named
  `<component>-<example>`. Show one in a page with `<Example @name="…" />`.
- Every example has a test, `docs-app/tests/examples/<name>-test.gts`, written with harness
  classes and ending in an axe audit. The guide shows it in the example's Test tab, so write it
  the way you'd want a reader to write theirs.

## The website

`docs/site/` (†) is hand-written HTML styled with Joinery's own CSS, not generated. The live demo
is `test-app/app`, built into `docs/site/demo/` by `pnpm demo:build`. When a change touches
anything the site shows (packages, components, arguments, an API used in a snippet), update
`docs/site/` in the same PR. `docs/social-card.html` is the source of `docs/site/social-card.png`.
