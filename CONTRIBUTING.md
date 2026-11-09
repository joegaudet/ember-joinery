# Contributing

> **Building.** Joinery lands in stages (see [JOINERY_PLAN.md](JOINERY_PLAN.md)). Anything
> marked † isn't there yet; a gate command marked † runs and passes, with nothing to check.

## Setup

```bash
pnpm install
pnpm build     # the test app, guide and examples import the packages' built output
pnpm start     # the demo (test-app); Vite prints its URL
```

pnpm runs scripts on Node 24 (`useNodeVersion` in `pnpm-workspace.yaml`).

The tests run in Chrome. Outside CI, testem uses the Playwright Chromium at
`/opt/pw-browsers/chromium` when there is one (cloud dev containers often have it), and
`CHROME_BIN` points it at any other Chrome or Chromium.

## The gate

CI runs exactly these; run them before opening a PR.

```bash
pnpm format:check
pnpm build
pnpm lint
pnpm typecheck
node --test scripts/*.test.mjs
pnpm test                          # test-app, Ember 7.3
pnpm --filter docs-app test        # every guide example and page
pnpm test:examples                 # vite-basic, classic, tailwind (formwright †), one at a time
pnpm parity                        # screenshot comparison with shadcn/ui (see "Parity")
```

CI also runs the suite on the previous LTS (6.12) by overriding `ember-source` for the whole
workspace. To do that locally, add `ember-source: ~6.12.0` directly under the top-level
`overrides:` key in `pnpm-workspace.yaml` (where CI's `sed` puts it), then run
`pnpm install --no-frozen-lockfile && pnpm build && pnpm test`, and revert both files afterwards.
Overriding only the test app loads two copies of Ember.

CI also runs the suite once more with CSS anchor positioning turned off, so the Floating UI
fallback is tested too. Locally that's `pnpm test:anchor-fallback`: it builds the test app with
`JOINERY_ANCHOR_FALLBACK=1`, which puts `globalThis.JOINERY_ANCHOR_FALLBACK = true` on the page
before any module runs. Until `@ember-joinery/primitives/anchor` (†) exists, that run repeats
the first. The contract for it: read that global each time it positions a part (not once at
import), and use Floating UI whenever it is `true`.

## Generated files

Files that every unit of work would otherwise touch are generated, so parallel changes never
collide. Don't edit them by hand.

- **Package barrels.** Each package's `src/index.ts` is written by `scripts/gen-barrels.mjs`
  from the modules present, every time the package builds or typechecks (`pnpm barrels` runs it
  alone). The barrels are gitignored. A package lists its barrel folders under
  `"joinery": { "barrels": [...] }` in its `package.json`; an add-on's `src/test-support` gets
  its own. A barrel re-exports every module's named exports, and a default export under the
  PascalCase of its file name (`button-group.gts` becomes `ButtonGroup`). That name can't spell
  an acronym (`input-otp.gts` gives `InputOtp`), so where upstream's name has one (`InputOTP`),
  export the component by that name instead of as the default. A folder with its own index
  (`anchor/index.ts`) counts as one module, and the files beside its index stay private. Names
  starting with `_`, and `-private` folders, stay out. Two modules exporting the same name fail
  the build.
- **The guide's page order.** Kolay orders a section's pages by its `meta.json` and fails the
  build if the list misses a page. The A–Z sections (Components, Primitives, Charts, Blocks,
  Formwright, Reference) get theirs from `scripts/gen-guide-meta.mjs`, which docs-app's Vite
  config runs on every build, test run and dev server start; those files are gitignored. A
  section's `index.md` is its overview and always comes first. Getting started, and the order
  of the sections themselves, are hand-written `meta.json` files: add a Getting started page to
  `docs-app/app/templates/getting-started/meta.json` where it belongs in the reading order.
- **The guide's page list.** The pages acceptance test builds its `PAGES` from
  `docs-app/app/templates`, so a new page is tested as soon as it exists.

## Packages and their build

The packages are v2 addons: `primitives` and `ember` build with `@embroider/addon-dev` and
rollup, `test-support` with `tsc`. Each one's `dist/` (and `declarations/`) is what the test app,
the guide and the examples import, so rebuild after changing a package. The build empties both
first, so a deleted module leaves nothing behind.

Every module in a rollup-built package's barrel is also a subpath export, one per feature
(`scripts/entrypoints.mjs` finds them with the barrel's rules). `src/visually-hidden.gts` is
`@ember-joinery/primitives/visually-hidden`; a folder feature, `src/anchor/index.ts`, builds to
`dist/anchor.js` and is `@ember-joinery/primitives/anchor`. Files beside a folder's index,
`-private` folders and `_` names are bundled into the modules that use them, not published on
their own; import them by relative path inside the package only. A file and a folder with the
same name (`anchor.ts` and `anchor/`) fail the build.

`@ember-joinery/ember` also builds its CSS: `packages/ember/build-css.mjs` lists the CSS files it
ships, and after every rollup build the Tailwind v4 CLI compiles each into `dist/`
(`dist/joinery.css` and the rest). In watch mode (`pnpm start` in the package), editing any CSS
file under `src/` rebuilds them.

## Porting a component

Joinery copies [ui.shadcn.com](https://ui.shadcn.com/). Port from the upstream source at the
commits pinned in `upstream.json`, never from memory. `node scripts/upstream.mjs fetch` checks
both repositories out at those commits into `.upstream/` (sparse and shallow, so it's quick), and
`upstream/inventory.json` lists each docs page's examples and the style each is shown in.

1. Read, in `.upstream/shadcn-ui`:
   - the component's source, `apps/v4/registry/bases/radix/ui/<name>.tsx`;
   - its rules in each style sheet, `apps/v4/registry/styles/style-*.css` (Nova is the default);
   - its docs page, `apps/v4/content/docs/components/radix/<name>.mdx`;
   - every example that page references (`<ComponentPreview name="…">`), in
     `apps/v4/examples/radix/` (or `examples/base/` where the page's `styleName` is `base-*`,
     as on Combobox).

   If ember-primitives has the component, read it in
   `.upstream/ember-primitives/ember-primitives/src/components/` too. To see an example as
   upstream renders it, run the parity app (`parity/README.md`).

2. Put the behaviour in `@ember-joinery/primitives`, the styled component in
   `@ember-joinery/ember`, and the harness in `@ember-joinery/test-support`.
3. Its styles come from the ported style sheets, `packages/ember/src/styles/<style>.css`, which
   `node scripts/port-styles.mjs` writes from upstream's (it renames `cn-` to `jn-`, drops the
   `.style-<name>` wrapper and puts each selector in `:where()`; don't edit them by hand).
   Upstream also writes utility classes inline in the component. For those, run
   `node scripts/extract-classes.mjs <name>`: it prints them as `@apply` rules, which go after
   the style sheet's rules. Keep its output whole, because the order is upstream's. Upstream's
   class list runs in call order: a string's semantic class, then its inline utilities, then
   the next string's (a cva's variant and size classes, a later `cn()` argument). Of two
   conflicting classes, the later wins. So an inline utility beats its own class's style rule
   but loses to a later class's: Badge's inline `focus-visible:ring-ring/50` loses to the ring
   colour in `jn-badge-variant-destructive`. The script checks each inline utility against the
   later classes' rules in all eight sheets. When a later class overrides it, the script moves it
   to a rule that skips that class (`:where(.jn-badge:not(.jn-badge-variant-destructive))`), and
   a `NOTE` marks any case this can't express. The output also lists the `group/*` markers the
   element must keep, and leaves conditional classes as comments.

A component is done when it has everything listed under "Definition of done for every
component" in the plan: its primitive, the styled component, its harness, tests written with the
harness (including the keyboard pattern, controlled and uncontrolled state, RTL and an axe audit),
a guide page with every upstream example, a parity mapping for each example, and a changeset.

## Tests first

Behaviour changes start with a failing test in `test-app/tests/`. Write tests with harness
classes, not raw selectors. A new component gets a harness class; page objects are harness
subclasses with `@child` declarations. Every test ends in an axe audit.

A component's harness extends `Harness` from `@ember-joinery/test-support`: it names its
`data-test-jn` value in `static component`, reaches its parts with `part()`, and reads state
through ARIA. The package's README covers the base class and the `data-test-jn-*` selector
reference, and `test-app/tests/fixtures/harness/` has small examples.

## Parity

`pnpm parity` renders each mapped upstream example in the React reference app (`parity/`) and
the matching Ember example in the guide's `/parity/<name>` route, then compares screenshots in
light and dark: the same fixed viewport, fonts and Chromium on both sides, with animations off.
The diff is measured over the content's bounding box, the smallest box holding everything on
either page that isn't the background (the whole page, if the two backgrounds differ), so an
empty stage or a missing part fails however small the example is. Two pixels count as different
when they are more than about 8 levels of grey apart, so a 1px `--border` line or a `--muted`
fill registers; pixelmatch still leaves anti-aliased edges out. A diff over the threshold (1% of
the box's pixels) fails, unless the map gives that example its own threshold along with a
written reason. Both pages showing nothing but the background is an error. The report, with the
compared areas and their diff side by side, is written to `parity-report/index.html` (CI uploads
it from `parity.yml`).

`parity/map/<component>.json`, one file per docs page, maps upstream example ids to Joinery
examples (the format is in `parity/map/README.md`). With `--require-complete`, an upstream example
missing from the map fails the check too; CI turns that on when the last component lands. With
nothing mapped, `pnpm parity` has nothing to compare and passes. To compare locally:

```bash
node scripts/upstream.mjs fetch
pnpm --dir parity install
pnpm exec playwright-core install chromium   # unless PLAYWRIGHT_BROWSERS_PATH already has it
pnpm build && pnpm guide:build
pnpm parity --only button          # components or upstream example ids; all mapped by default
```

The comparison runs playwright-core's own Chromium build, as CI does. `PARITY_CHROMIUM` points it
at another Chromium binary, but that one's screenshots won't match CI's, so use it to look, not to
set thresholds. `parity/README.md` has the details, including the fonts and why the stages leave
out the docs pages' preview classes.

## Upstream sync

`node scripts/upstream.mjs changes` lists what changed upstream since the commits in
`upstream.json` (ui sources, style rules, examples, docs pages, charts, blocks, and
ember-primitives' `src`), mapped to Joinery components, plus any new upstream components.
ember-primitives' modules map to Joinery's through `EMBER_PRIMITIVES` in the script, so add a
module there when Joinery covers a new one. A weekly workflow (`upstream.yml`) keeps a tracking
issue up to date with it. When the report is longer than an issue can hold, the issue gets the
first part and links to the run's summary, which has all of it. A sync PR ports the changes and
moves `upstream.json` forward in the same PR, then reruns `node scripts/upstream.mjs inventory`
and `node scripts/port-styles.mjs`. Nothing else changes `upstream.json`; CI checks that the
inventory and the ported style sheets match it.

## Changesets

Every change to a published package needs a changeset (`pnpm changeset`). The packages version
together.

## Releasing

A release is cut by pushing a tag. Nothing publishes on a push or a merge: `release.yml`
publishes only from a pushed `v*` tag, and `bootstrap-publish.yml` only when someone dispatches
it by hand. `scripts/release-workflows.test.mjs`, in the gate, checks both.

1. PRs that change a published package carry a changeset (`pnpm changeset`). While any are
   pending on `main`, CI keeps a "chore: version packages" PR open, on the branch
   `changeset-release/main`, with the next version and the changelogs.
2. Merge that PR.
3. Tag the merge commit with the new version and push the tag:

   ```bash
   git switch main && git pull
   git tag -a v1.0.0 -m v1.0.0
   git push origin v1.0.0
   ```

`release.yml` checks that the tag is on `main` and matches every public package's version. Then
`pnpm release` builds the packages and publishes whatever isn't already on npm through
`scripts/publish.mjs` (OIDC trusted publishing with provenance; there is no `NPM_TOKEN`), and the
job creates the GitHub release. If a run fails, re-run it: it skips what is already published.
The script replaces `changeset publish`, which hands the publish to pnpm, and pnpm supports
neither OIDC nor provenance; its header explains. `node scripts/publish.mjs --dry-run` packs and
checks every package without publishing anything (it asks the registry what is already there, so
it needs the network).

**A brand-new package** can't publish through OIDC, because npm only configures a trusted
publisher for a name that already exists. Its first release goes out once through
`bootstrap-publish.yml`, behind the `npm-bootstrap` environment, using a short-lived `NPM_TOKEN`
environment secret (the file's header has the steps). Dispatch it on `changeset-release/main`
while the version PR is open, so each new name's first version is the release itself. After
that, set `joegaudet/ember-joinery` / `release.yml` as the package's trusted publisher on
npmjs.com; the tag push then finds nothing left to publish and only creates the GitHub release.
Once every package has been published, delete the workflow and the environment, and restore the
file from git history when a new package needs its first publish.

**1.0.0** is that case for every package. The changesets that build up before the first release
(`.changeset/core-packages.md` is a major bump from 0.0.0) become 1.0.0, and all of it goes out
through `bootstrap-publish.yml`. The npm org `@ember-joinery` has to exist first; only the npm
website can create one.

The version PR is opened by a GitHub App, not `GITHUB_TOKEN`: GitHub runs no workflows for
pushes made with `GITHUB_TOKEN`, so the PR would never get its required checks. One App can serve
every repository that uses this workflow, Formwright's included. To set it up:

1. Create a GitHub App (Settings → Developer settings → GitHub Apps → New) with webhooks off and
   repository permissions **Contents: read and write** and **Pull requests: read and write**, or
   reuse the one you have.
2. Install it on this repository.
3. Generate a private key, then in this repository (Settings → Secrets and variables → Actions)
   add the variable `RELEASE_APP_CLIENT_ID` (the App's client ID) and the secret
   `RELEASE_APP_PRIVATE_KEY` (the whole `.pem` file).

Until both are set, the version job is skipped instead of failing, and you open the version PR
yourself, on the same branch so `bootstrap-publish.yml` can run there:

```bash
git switch -c changeset-release/main origin/main
pnpm changeset version
git add -A && git commit -m 'chore: version packages'
git push -u origin changeset-release/main
gh pr create --base main --title 'chore: version packages' --body 'Versions and changelogs.'
```

## The guide

`docs-app/` is the guide at `/ember-joinery/guide/`, built with
[Kolay](https://github.com/universal-ember/kolay). `pnpm guide:start` serves it locally, and
`pnpm guide:build` builds it into `docs/site/guide/` (with `docs/site/404.html`, so deep links
load on GitHub Pages). Its tests run in the same Chrome as the test app's.

- There is one page per component, `docs-app/app/templates/components/<name>.md`, laid out like
  its ui.shadcn.com page. Primitives, charts, blocks and the Formwright bridge have sections of
  their own. The A–Z sections' `meta.json` files are generated (see "Generated files"), and
  `docs-app/tests/acceptance/pages-test.ts` renders every page and audits it with axe, so a new
  page needs no list edited.
- Examples are `.gts` files in `docs-app/app/examples/`, one per upstream example, named
  `<component>-<example>`, each exporting the example as its default export. Show one in a page
  with `<Example @name="…" />` (add `@title`, and `@align="start"` where upstream's preview
  aligns it). The frame has Preview, Template and Test tabs and a copy button.
- Upstream's right-to-left examples (`<name>-rtl`, whose `<ComponentPreview>` has
  `direction="rtl"`) are shown with `<Example @name="<name>-rtl" @dir="rtl" />`. `@dir` puts
  `dir` on the preview, as the parity route's `?dir=rtl` does, and Joinery's components take
  their direction from the nearest `dir`, so the example needs no provider of its own. Port
  the Arabic text: upstream's preview opens in Arabic (it also offers Hebrew and English, a
  picker the frame doesn't have).
- Every example has a test, `docs-app/tests/examples/<name>-test.gts`, written with harness
  classes and ending in an axe audit. The guide shows it in the example's Test tab, so write it
  the way you'd want a reader to write theirs. `docs-app/tests/unit/examples-test.ts` fails
  when an example has no test, a test has no example, or a test never calls `a11yAudit()`.
- The guide's own CSS (`docs-app/app/styles/app.css`) sits in `@layer guide`, below
  `@layer joinery`, so Joinery's rules win wherever a component renders. The example's preview
  and the parity route are a `guide-stage`, and the guide's rules stop there: its prose and
  link rules are `@scope`d to stop at an example, its `box-sizing: border-box` reset covers the
  stage but not what's inside, and the text styles the page would pass down (font, size, line
  height, colour) start over, as in upstream's preview. The stage adds no reset of its own, so
  the guide and the parity comparison see Joinery as an app without Tailwind does. That
  includes box sizing: upstream's parts get `border-box` from Tailwind's preflight, so a part
  whose size depends on it sets it in joinery.css, and the parity comparison catches one that
  doesn't. Keep new guide rules inside the layer, and scope any that select bare elements or
  every element.
- `/parity/<name>` renders one example with no frame and no guide around it, centred as
  upstream's preview is, for the screenshot comparison. `?theme=dark` puts `.dark` on `<html>`
  and `?theme=light` (the default) puts `.light` there; either also pins `color-scheme`, so the
  browser's or OS's preference can't change the page. `?dir=rtl` lays it out right to left,
  and `?align=start|end` places it. The example's root carries `data-parity="<name>"`; an
  unknown name renders `data-parity-missing` instead.

## The website

`docs/site/` is hand-written HTML, not generated. For now `site.css` is a placeholder that uses
shadcn's token names; the finished site is styled with Joinery's own CSS. The live demo is
`test-app/app`, built into `docs/site/demo/` by `pnpm demo:build`, and `pages.yml` builds the
demo and the guide into `docs/site/` and deploys it from `main` (CI's `site` job runs the same
builds on every PR, so a break shows before the merge). The deploy needs the
repository's Pages source set to "GitHub Actions" (Settings, Pages), a repository setting only
the maintainer can change. When a change touches anything
the site shows (packages, components, arguments, an API used in a snippet), update `docs/site/`
in the same PR. `docs/social-card.html` is the source of `docs/site/social-card.png`; its header
has the command that renders it.

## The example apps

`examples/` holds an app for each way Joinery is consumed: `ember-vite-basic` (Vite and
Embroider), `ember-classic` (classic ember-cli with ember-auto-import 2) and `ember-tailwind`
(Vite with Tailwind CSS v4). Each asks for the published version ranges, which the workspace
overrides with the local packages, and each has a smoke test that `pnpm test:examples` and CI
run.

The Tailwind app declares `@layer theme, base, joinery, components, utilities;` before
importing Tailwind: Joinery's layer above `base`, so preflight's resets don't undo its rules,
and below `utilities`, so a class on a component overrides them. Its tests check both.

Two things wait on later work. The smoke tests only import the packages so far; the first
display component (†) renders itself in each of them, which is what proves a classic app
consumes `.gts` v2 addon components. And the apps import only `joinery.css`: the theme (†)
adds `tokens.css` to every app and `tailwind.css` to the Tailwind one, and the Installation
page with them.
