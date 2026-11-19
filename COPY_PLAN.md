# Plan: copy components into your app (`npx ember-joinery add`)

Status: built (2026-11-19) on `feature/joe/copy-cli`, branched from `build/joinery-1.0`, not
committed. Decision 2 is recorded as changed in `JOINERY_PLAN.md`. Where the build differs from the
steps below:

- **TypeScript only.** The copies are `.gts`, so an app needs TypeScript in its Babel config. The
  CLI warns when `package.json` has no `typescript`. A JS mode (shadcn's `tsx: false`, stripping
  the types to `.gjs`) is later work.
- **End to end in `test-app`, not the examples.** The examples are plain JS. `test-app`'s
  `pnpm copy` runs `ember-joinery add --all` before it typechecks and tests, and
  `tests/integration/copied-components-test.gts` drives a copied Dialog with `DialogHarness`.
  The update path is covered by the CLI's unit tests.
- **The manifest builder is `packages/cli/lib/build-registry.mjs`** (step 2's
  `scripts/copy-manifest.mjs`). Its tests are `scripts/cli-registry.test.mjs`, and the CLI's are
  `scripts/cli.test.mjs`, so the existing gate runs them.
- **Reference test.** `scripts/api-docs.test.mjs` now asks a Reference page only of Ember
  add-ons, and checks that the CLI is documented on the Copy components page.
- **No `--no-install`.** shadcn has no such flag. An `@ember-joinery/*` package is bumped only when
  the app's range is older, and a `workspace:` or `file:` spec is left alone.

## The idea

shadcn/ui's main selling point is that you own the code: you run one command and the component's
source is copied into your app. Joinery ships only as npm add-ons today. This plan adds the same
copy path with Joinery's own CLI, and npm stays the default.

```bash
npx ember-joinery add dialog
```

That command writes `dialog.gts` into `app/joinery/`, along with `button.gts`, `icon.gts` and the
`-private` files that `dialog.gts` imports. It then prints, or runs, the install for the npm
packages the copy still needs: `@ember-joinery/primitives` and `lucide`.

The copy keeps its `jn-*` classes and its `data-test-jn-*` attributes. That means `joinery.css`
still styles it and `@ember-joinery/test-support` still drives it. You own the markup and the
behaviour, and your tests don't change.

The feature has three deliverables, and all three land in one PR:

- the CLI (steps 2–4);
- the guide (step 5), covering a new "Copy components" page and a copy command on every
  component page;
- the marketing site (step 6), covering the hero, Why, Install and the package table.

The CLI is plain Node, with no shadcn or React tooling involved. It ships in the unscoped
`ember-joinery` package, a name `setup-ember-joinery.sh` already reserves on npm.

## Decisions to confirm (Joe's call)

1. **Styles stay in `joinery.css` (recommended).** Copies render the same `jn-*` classes, and the
   app keeps importing Joinery's CSS, which is what decision 13 says. Owning the styles too would
   mean emitting each component's `@apply` rules for each style, and that needs Tailwind in the
   app. Treat that as a later flag (`--css`, for Tailwind apps).
2. **When it lands: after 1.0 (recommended).** The alternative is a unit on the
   `build/joinery-1.0` stacked PR. That PR is otherwise finished, and this feature is a new
   package with its own release.
3. **Where the source comes from: inside the CLI's own tarball (recommended).** The alternative is
   fetching from the site. Decision 37 versions all packages together. So
   `npx ember-joinery@1.2.0 add dialog` copies exactly 1.2.0's source and pins
   `@ember-joinery/primitives@^1.2.0`. That works offline and needs no hosting or registry.
4. **Installing dependencies.** Option A: detect the package manager from the lockfile and run
   the install (`--no-install` skips it). Option B: print the command. The recommendation is to
   run it, since that is what users expect from this kind of tool.

## Commands (v1): shadcn's `add`, flag for flag

Adding and updating are both done with `add`, as in shadcn. shadcn has no `update` command:
you update a copy by running `add` again, and its flags let you look before anything is
written. Joinery keeps shadcn's names, short forms and defaults, so shadcn's docs and habits
carry over unchanged.

```bash
npx ember-joinery add dialog                 # add (and whatever it imports)
npx ember-joinery add dialog --dry-run       # update, step 1: which files would change
npx ember-joinery add dialog --diff          # step 2: your copy against this version
npx ember-joinery add dialog --diff dialog.gts
npx ember-joinery add dialog --overwrite     # step 3: take this version's files
```

| Flag            | Short | Does                                                                                                             | Default   |
| --------------- | ----- | ---------------------------------------------------------------------------------------------------------------- | --------- |
| `--yes`         | `-y`  | Skip the confirmation prompt                                                                                     | `false`   |
| `--overwrite`   | `-o`  | Overwrite existing files                                                                                         | `false`   |
| `--cwd <cwd>`   | `-c`  | Working directory                                                                                                | current   |
| `--all`         | `-a`  | Add every core component                                                                                         | `false`   |
| `--path <path>` | `-p`  | Where the files go                                                                                               | see below |
| `--silent`      | `-s`  | Mute output                                                                                                      | `false`   |
| `--dry-run`     |       | List what would be written, created, overwritten or skipped (unchanged); write nothing                           | `false`   |
| `--diff [path]` |       | Unified diff of your copy against this version: the first 5 changed files, or that one file. Implies `--dry-run` | —         |
| `--view [path]` |       | Print this version's file: the first 5, or that one. Implies `--dry-run`                                         | —         |

Behaviour, as shadcn's:

- **Existing files.** Without `--overwrite`, a file that already exists and differs prompts
  "already exists, overwrite?". With `--yes`, or when there is no TTY (CI), the file is skipped,
  and the CLI says which files it skipped. A file identical to this version's is left alone
  silently.
- **Dependencies.** Components the requested one imports are added too, under the same rules.
  So `add dialog --overwrite` also updates `button.gts` if it changed. `--dry-run` lists them.
- **npm packages.** It installs the missing ones with the app's package manager, detected from
  the lockfile. An update that needs a newer `@ember-joinery/primitives` bumps it.
- **Where files go.** Joinery's counterpart to `components.json`'s `aliases.ui` is
  `joinery.json`, holding `{ "$schema": …, "path": "app/joinery" }`. The first `add` writes it,
  with `--path` or the default. Later runs read it, so an update goes to the same place without
  repeating `--path`. That's the one piece of config. There's no `init` command; the first `add`
  does `init`'s job.
- **`list`** prints the components this version can add.
- Not copied from shadcn: registry names, URLs and namespaces (`@acme/x`). The source is this
  package's own, at its own version.

## Steps (TDD: each script's test first, red, then green)

### 1. Record the decision

- In `JOINERY_PLAN.md`:
  - add a deviation bullet at the top;
  - rewrite decision 2's row to read "npm v2 add-ons, plus `npx ember-joinery add` to copy a
    component's source in";
  - add `packages/cli/` (`ember-joinery`) to "Target layout".
- In `CLAUDE.md`, add one line to "A component ships whole": a component is copyable, which a
  test checks.

### 2. The manifest: `scripts/copy-manifest.mjs` (+ test)

1. Walk `packages/ember/src/components/*.gts` and follow each file's relative imports
   (`./icon.gts`, `../-private/*.gts`). Reuse the import parsing in `gen-barrels.mjs` and
   `entrypoints.mjs`.
2. Emit `manifest.json`, with one entry per public component:
   - its files;
   - the components it needs;
   - the npm packages it imports, with their ranges from `packages/ember/package.json`
     (`@ember-joinery/primitives` pinned to the release version).
3. Copy the sources into the CLI package at `prepack`.

The copies keep the package's folder layout (`components/`, `-private/`), so relative imports
need no rewriting. `app/joinery/` sits outside `app/components/`, so the classic resolver ignores
it. Apps import the copied files by path.

The tests check that:

- every export in `index.ts` has an entry;
- every relative import is covered;
- no copied file imports `@ember-joinery/ember`;
- a snapshot of `dialog`'s entry still matches.

### 3. The CLI: `packages/cli/` (`ember-joinery`, with a `bin`)

- Write it in plain Node ESM using only built-ins (`node:fs`, `node:util` `parseArgs`). It adds
  no dependencies.
- Its logic is `add` and `list` over the manifest, plus package-manager detection from the
  lockfile and `joinery.json`.
- The diffs come from `node:util`'s `diff` where the Node version has it; otherwise a small
  line diff is written. No dependency is added for it.
- Unit tests in `packages/cli/test/*.test.mjs` (node:test) cover:
  - the dependency closure;
  - each flag in the table above, and the existing-file rules (prompt, skip under `--yes` and
    without a TTY, replace with `--overwrite`, leave identical files alone);
  - that `--dry-run`, `--diff` and `--view` write nothing;
  - `--diff`'s five-file limit and its one-file form;
  - that `joinery.json` is written on the first `add` and read after;
  - that an update bumps `@ember-joinery/primitives`;
  - that an unknown name is an error that lists the near matches.
- It is wired up as the other packages are: `files`, `prepack`, `legal-files`, the
  `.changeset/config.json` fixed group (it is unscoped, so it has to be added by name),
  `publish.mjs` / `publish-plan.mjs`, `release-workflows.test.mjs`, and `bootstrap-publish.yml`
  for its first release.

### 4. Prove it end to end (CI)

A new CI job:

1. packs the CLI;
2. runs `npx ./ember-joinery-*.tgz add --all --no-install` into a copy of
   `examples/ember-vite-basic`, and into `examples/ember-classic`;
3. runs each example's typecheck and build;
4. runs a test that renders the copied `Dialog`, drives it with `DialogHarness`, and ends with an
   axe audit;
5. tests the update path: it edits a copied file, then checks that
   `add dialog --diff` shows the edit and `add dialog --yes` keeps it.

That test backs the claim that harnesses work on copies. The harnesses already import nothing
from `@ember-joinery/ember`, because they work from DOM attributes only.

### 5. Guide (`docs-app/`), in the same PR as the CLI

`CLAUDE.md` requires a public API change to update its guide page in the same PR, and the CLI
is public API. The guide has three parts to change.

**a. A new Getting started page: `docs-app/app/templates/getting-started/copy.md`, "Copy
components".**

Add `"copy"` to `getting-started/meta.json`'s `order`, after `"installation"`. The page has
these sections:

1. **Install or copy.** npm add-ons get fixes with `pnpm update`. Copies are yours to change,
   and get fixes only when you run `add` again. Most apps install; copy when you need to change
   a component's markup or behaviour.
2. **Add a component.** `npx ember-joinery add dialog`, showing the CLI's real output: which
   files were created and which npm packages were installed. Then where the files land
   (`app/joinery/components/`, `app/joinery/-private/`) and how to import one:
   `import { Dialog } from 'my-app/joinery/components/dialog'`.
3. **What stays from npm.** `@ember-joinery/primitives`, `lucide`, and Joinery's CSS (the
   `jn-*` classes are unchanged, so the import in `app/app.ts` stays). Also
   `@ember-joinery/test-support`: `DialogHarness` drives a copy as it drives the package's
   Dialog, so the page shows a test written against the copy.
4. **`joinery.json`.** What it holds, and that the first `add` writes it.
5. **Update a component.** shadcn's flow, step by step:
   - `--dry-run`, to see which files would change;
   - `--diff dialog.gts`, to see what's new against your edits;
   - merge by hand, or `--overwrite`;
   - and that `--yes` never overwrites a file you've changed.
6. **Options.** The flag table from "Commands" above.
7. **What can't be copied yet.** The add-on packages, the primitives and the blocks (for blocks,
   the example frame's Copy button already copies them).

**b. `installation.md`.**

- Under the intro, one paragraph: "or copy the components' source in with
  `npx ember-joinery add`", linking to the new page.
- The "Not on npm yet" callout covers the CLI too, until 1.0 publishes.

**c. Every component page's `## Installation`.**

Today each page shows only `pnpm add @ember-joinery/ember lucide`. Each page shows two
labelled blocks, as ui.shadcn.com's CLI and Manual tabs do:

````md
## Installation

Install the package:

```bash
pnpm add @ember-joinery/ember lucide
```

Or copy the component's source into your app ([Copy components](/getting-started/copy.md)):

```bash
npx ember-joinery add dialog
```
````

- These are plain code blocks, not a `<Tabs>`. The Template tab's copy button already works on
  code blocks, and the acceptance test renders them with nothing new.
- The command names the manifest entry. For a page whose component imports others (Dialog
  imports Button), add one line saying `add` brings those along.
- About 67 pages change, so a one-off script (not committed) inserts the block.
- `docs-app/tests/unit/copy-commands-test.ts` keeps the pages honest. It fails when:
  - a page under `templates/components/` for a core component has no `npx ember-joinery add
<name>`;
  - a page names a component that isn't in the manifest;
  - a page for an add-on package has one.
- Add-on pages (Chart, Carousel, Data Table, Code Block, File Upload, Tiptap, Power Calendar,
  Maskito, Formwright) get a line instead: "Copying is not available for add-on packages yet;
  install the package."

**d. The Testing page (`testing.md`).** One sentence: harnesses work on copied components too,
because they look elements up by `data-test-jn-*`, which a copy keeps.

### 6. Marketing site (`docs/site/index.html`) and README, in the same PR

`CLAUDE.md` requires the hand-written site to change in the same PR, and `scripts/site.test.mjs`
holds it to the repository. Five places on the page change.

**a. Hero (`.install`, around line 190).**

- Keep the one-line `pnpm add @ember-joinery/ember`.
- Below it, a second `.install` line, in the same markup: `npx ember-joinery add button`.
- The `install-note` gains a few words: "or copy the source in and own it."

**b. `#why`, "shadcn's design, the Ember way".**

Add a short paragraph and a `.pair` after the existing React-against-Ember pair: "Own the code,
as with shadcn." The pair shows, on one side, `npx ember-joinery add dialog` and its output, and
on the other, the copied file's first lines and the harness test that still passes against it.
This is the section that says Joinery is shadcn for Ember, so the copy story belongs here and
not only under Install.

**c. `#install`, "Vite or classic, Tailwind or not".**

- After the first `.pair` (`pnpm add` and the CSS imports), add a subheading, "Or copy the
  source in", and a `.pair`:
  - on the left, `npx ember-joinery add dialog` and an update with `--diff` / `--overwrite`;
  - on the right, `app/joinery/components/dialog.gts` and `joinery.json`.
- Then one paragraph: copies keep Joinery's CSS and harnesses, and here's how to update them.
  It links to `guide/getting-started/copy.md`.
- Add a row for `ember-joinery` to the package table: "The CLI: copies a component's source
  into your app, and updates it."

**d. `#guide`.**

Add one clause saying each component page shows its copy command beside its install command.

**e. `scripts/site.test.mjs`.**

- The existing "names every published package in #install" test fails until `ember-joinery`'s
  row is added. That is the red step.
- New assertions:
  - the hero and `#install` both show `npx ember-joinery add`;
  - `#install` links to `guide/getting-started/copy.md`, and that page exists in
    `docs-app/app/templates`;
  - every component named in an `ember-joinery add` snippet on the page is in the manifest.

**f. Screenshots and social card.** No change. The component grid's screenshots are unaffected.

**g. `README.md` and `packages/cli/README.md`.**

- The root README's install section gets the same two options as the site's `#install`, with
  the same link.
- The CLI's own README (the npm page) holds:
  - the command and the flag table;
  - the update flow;
  - a link to the guide page.

### 7. Contributor docs and release

- **`CONTRIBUTING.md`:**
  - "Porting a component": nothing to do, because the manifest is generated and checked;
  - the gate: add the CLI's tests;
  - "Releasing": add the new package.
- **A changeset for `ember-joinery`.**

## Not in v1 (later)

- Copying from add-on packages (chart, carousel, data-table and the others).
- Copying blocks (the guide's Copy button already covers them).
- `--css`, to own a component's styles (decision 1 above).
- Copying primitives.
- An `init` command. The first `add` writes `joinery.json`.
- shadcn's `search`, `view` and `migrate` commands.

## Risks

- **Copies drift.** Users own their copies, so fixes reach them only when they run `add` again.
  The guide page says so and shows the `--diff` flow.
- **The manifest falls behind the components.** A new import or a new component could be missed.
  The manifest test and the CI job in step 4 catch that.
