# Joinery: shadcn/ui for Ember, as a Formwright sibling

Status: Phase 0 (2026-11-08). The plan was agreed through a 40-question intake. The repo and the
`@ember-joinery` npm org exist; nothing is built yet.

**What we're copying:** [ui.shadcn.com](https://ui.shadcn.com/): every component, every example
on its component pages, a subset of its blocks, and its theming. The source of truth is the code
that builds that site, `shadcn-ui/ui` `apps/v4/` (the Radix "new-york-v4" registry), pinned at
`8ab2771` (2026-11-08). Joinery also covers every feature of
[ember-primitives](https://github.com/universal-ember/ember-primitives) 0.64.2 (`9584c78`).
Both are MIT.

Joinery follows the Formwright methodology: v2 addons in a pnpm monorepo, strict TypeScript and
Glint, `.gts` everywhere, a harness class for every component, a Kolay guide whose examples
are all tested, a hand-written marketing site with a live demo, Changesets, and tag-triggered
OIDC releases.

## Decisions (from intake)

| #   | Area            | Decision                                                                                                                                                                 |
| --- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | Name            | **Joinery**. Repo `joegaudet/ember-joinery`, npm `@ember-joinery/*`                                                                                                      |
| 2   | Distribution    | npm v2 addons only; no copy-in CLI                                                                                                                                       |
| 3   | Packages        | Core plus opt-in add-ons, one add-on per heavy dependency                                                                                                                |
| 4   | Positioning     | Its own brand. "Design and API ported from shadcn/ui (MIT)" in the README, the site footer and `NOTICE`                                                                  |
| 5   | Primitives      | Our own headless `@ember-joinery/primitives`, covering all of ember-primitives plus the Radix parts shadcn needs. No ember-primitives dependency                         |
| 6   | Repo            | `joegaudet/ember-joinery`, public, created with `gh` from Joe's machine                                                                                                  |
| 7   | Plan            | This file, committed as `JOINERY_PLAN.md` in the repo's first PR                                                                                                         |
| 8   | Process         | Review this plan, then one PR per phase, each passing the full gate; Joe merges                                                                                          |
| 9   | Ember           | 7.3 (latest) and 6.12 (previous LTS), both in CI                                                                                                                         |
| 10  | Consumers       | Vite/Embroider and classic ember-cli apps, each with an example app in CI                                                                                                |
| 11  | Composition     | Yielded parts: `<Dialog as \|d\|><d.Trigger>…</d.Trigger><d.Content>…`                                                                                                   |
| 12  | State           | Controlled or uncontrolled, as in Radix: `@open`/`@defaultOpen`/`@onOpenChange`, `@value`/`@defaultValue`/`@onValueChange`                                               |
| 13  | Styling         | Written with Tailwind v4 using shadcn's exact class strings, shipped as compiled CSS on semantic classes in `@layer joinery`. Tailwind is optional for apps              |
| 14  | Tokens          | shadcn's names in OKLCH (`--background`, `--primary`, `--ring`, `--radius`, `--chart-1..5`, `--sidebar-*`…), so any shadcn theme pastes in unchanged                     |
| 15  | Variants        | Typed `@variant` and `@size` args, rendered as `data-variant` and `data-size`                                                                                            |
| 16  | Dark mode       | A `.dark` class, plus a color-scheme utility (follows the OS, saves the choice, syncs tabs)                                                                              |
| 17  | Floating parts  | The Popover API for layering. CSS anchor positioning where the browser has it, `@floating-ui/dom` otherwise. Supported: the last 2 versions of evergreen browsers        |
| 18  | `asChild`       | An `@as` tag, plus a yielded modifier for each part that needs one, e.g. `<LinkTo {{d.trigger}}>`                                                                        |
| 19  | Accessibility   | WCAG 2.2 AA: an axe audit in every test, plus APG keyboard and focus tests for each component                                                                            |
| 20  | i18n            | RTL: logical properties, a Direction provider, arrow keys flip. Every built-in string is an arg with an English default                                                  |
| 21  | Scope           | All ~67 shadcn components, the chat set included, plus every ember-primitives component                                                                                  |
| 22  | Utilities       | ember-primitives' non-visual utilities go in `@ember-joinery/primitives`, one subpath export per feature                                                                 |
| 23  | Heavy deps      | We write Command, Drawer, Toast, Resizable, OTP and Calendar ourselves. Add-ons wrap embla-carousel, `@tanstack/table-core`, shiki and d3                                |
| 24  | Charts          | Declarative Glimmer SVG on `d3-scale` and `d3-shape`, with an API shaped like recharts                                                                                   |
| 25  | Formwright      | `@ember-joinery/formwright`: Joinery controls as Formwright controls, a Field-anatomy layout, and harnesses                                                              |
| 26  | Icons           | Lucide (the framework-agnostic `lucide` package), imported per icon. Apps get `<Icon>`, and every icon slot can be replaced                                              |
| 27  | Blocks          | Login, signup, dashboard with sidebar, and settings, as tested guide examples and in the demo (not exported)                                                             |
| 28  | Dates           | `Date` in and out (`{ from, to }` for ranges), formatted with `Intl`; no date library                                                                                    |
| 29  | Harness pkg     | `@ember-joinery/test-support`; each add-on exports its own harnesses from a `/test-support` subpath                                                                      |
| 30  | Harness lookup  | `data-test-jn-*` attributes find and scope; state is read through ARIA                                                                                                   |
| 31  | Harness compose | Formwright-style decorators (`@child`, `@form`) plus `find()` for one-off lookups. Portalled content is followed through its owner id                                    |
| 32  | Runners         | `@ember/test-helpers` (QUnit or Vitest)                                                                                                                                  |
| 33  | Site CSS        | Hand-written HTML styled with Joinery's own compiled CSS (no Pico)                                                                                                       |
| 34  | Guide           | One page per component, laid out like ui.shadcn.com's                                                                                                                    |
| 35  | Guide extras    | Theme switcher, RTL and width toggles, a theme builder page, generated API reference                                                                                     |
| 36  | Brand           | The sibling layout and type of Formwright and real-enums, with its own accent and logo (a dovetail mark)                                                                 |
| 37  | Release         | Formwright's machinery: Changesets with all packages versioned together, a version PR from the GitHub App, a release on a pushed tag (OIDC), and `bootstrap-publish.yml` |
| 38  | Versions        | Each finished phase publishes a 0.x minor; 1.0 at parity                                                                                                                 |
| 39  | Siblings        | PRs to ember-formwright and real-enums adding Joinery to their sibling lists, and a pointer in Formwright's guide                                                        |
| 40  | Fidelity        | CI compares screenshots with shadcn's own examples, in light and dark. An upstream watch lists what changed upstream since the last sync                                 |

**Defaults I chose without asking; please check them:** the MIT licence plus a `NOTICE` file; the core
package is named `@ember-joinery/ember` (like `@ember-formwright/ember`); the test prefix is `jn`; Node
≥ 22.12, pnpm 10, TypeScript 6; QUnit with ember-a11y-testing; GitHub Pages at
`joegaudet.com/ember-joinery/`, with `/guide/` and `/demo/` under it; the default font is the
system stack, with Geist in the guide and the parity runs (as on ui.shadcn.com).

## Target layout

```
ember-joinery/
  packages/
    primitives/    @ember-joinery/primitives    headless behaviour and utilities (ember-primitives parity, Radix parts)
    ember/         @ember-joinery/ember         styled components, joinery.css, tokens.css, themes/, tailwind.css, <Icon>
    test-support/  @ember-joinery/test-support  a harness for every primitives and core component, and the selector reference
    chart/         @ember-joinery/chart         Glimmer SVG charts on d3-scale and d3-shape   (+ /test-support)
    carousel/      @ember-joinery/carousel      embla-carousel                              (+ /test-support)
    data-table/    @ember-joinery/data-table    @tanstack/table-core                        (+ /test-support)
    code-block/    @ember-joinery/code-block    shiki highlighting, line numbers, diff, copy  (+ /test-support)
    formwright/    @ember-joinery/formwright    Formwright controls, Field layout, harnesses  (+ /test-support)
  test-app/        Vite Ember app: integration tests for every package; built into docs/site/demo/
  docs-app/        the Kolay guide → docs/site/guide/
  parity/          private: React 19 + Tailwind 4 reference app that renders shadcn's own examples
  examples/        ember-vite-basic, ember-classic, ember-tailwind, ember-formwright (each runs in CI)
  docs/site/       hand-written marketing page (index.html, site.css, logo.svg, favicon.svg, social-card.png)
  docs/social-card.html
  scripts/         publish.mjs, publish-plan.mjs (from Formwright), upstream.mjs, parity.mjs,
                   extract-classes.mjs, site-screenshots.mjs, *.test.mjs
  upstream.json    the shadcn-ui/ui and ember-primitives commits last synced
  CLAUDE.md  CONTRIBUTING.md  README.md  LICENSE.md  NOTICE  JOINERY_PLAN.md
  .changeset/  .github/workflows/{ci,parity,upstream,pages,release,bootstrap-publish}.yml
```

## Architecture

### Layers

`primitives` (behaviour, no styles) → `ember` (styled; mostly thin layers over the primitives) →
add-ons. `test-support` mirrors them: a harness for each primitive, and the styled components
reuse those harnesses because the parts and selectors are the same. You can use a primitive on
its own, unstyled, the way you'd use ember-primitives or Radix.

### Modern Ember rules (enforced by lint and review)

- `.gts` template-tag components in strict mode. Glimmer components, or `TOC` for
  template-only ones. Named args only, and `...attributes` on the main element.
- Glint signatures for every component: `Args`, `Blocks`, `Element`. Every yielded part is typed.
- `@tracked` state, native getters and `@cached`. Function-based modifiers via `ember-modifier`.
  Built-ins (`on`, `fn`, `hash`, `array`, `element`) instead of helper addons.
- No `@ember/component`, mixins, observers, `{{action}}`, positional params, or an app-wide
  service a component can't work without. Owner-scoped state (Toaster, color scheme) goes
  through the primitives' `service` helper, so tests stay isolated.

### Component anatomy (Dialog as the worked example)

```gts
import { Dialog, Button, Input } from '@ember-joinery/ember'

<template>
  {{! uncontrolled; pass @open and @onOpenChange to control it }}
  <Dialog @name="edit-profile" as |d|>
    <d.Trigger @as="span">Edit profile</d.Trigger>   {{! or <LinkTo {{d.trigger}}> on your own element }}
    <d.Content @closeLabel="Close">
      <d.Header>
        <d.Title>Edit profile</d.Title>
        <d.Description>Make changes to your profile here.</d.Description>
      </d.Header>
      <Input @value={{this.name}} @onValueChange={{this.setName}} />
      <d.Footer>
        <d.Close>Cancel</d.Close>
        <Button @variant="default" {{on "click" this.save}}>Save changes</Button>
      </d.Footer>
    </d.Content>
  </Dialog>
</template>
```

Attributes on every part:

| Attribute                                                                                                       | Purpose                                                                                       |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| `class="jn-<slot>"`                                                                                             | The styling hook; selectors sit inside `:where()` in `@layer joinery`, so app CSS always wins |
| `data-slot="<slot>"`                                                                                            | Same as shadcn v4 (`dialog-content`, `button`…), for parity and for app CSS                   |
| `data-state`                                                                                                    | Same as Radix: `open`/`closed`, `checked`/`unchecked`, `active`/`inactive`, `on`/`off`        |
| `data-variant`, `data-size`, `data-side`, `data-align`, `data-orientation`, `data-disabled`, `data-highlighted` | Variants and state for CSS                                                                    |
| `data-test-jn="<component>"`, `data-test-jn-name="<@name>"`                                                     | Root of a component instance (the harness's scope)                                            |
| `data-test-jn-part="<part>"`                                                                                    | A part (`trigger`, `content`, `item`, `option`…)                                              |
| `data-test-jn-owner="<id>"`                                                                                     | On portalled or top-layer parts: the root they belong to                                      |
| `data-test-jn-value="<key>"`                                                                                    | Options, items, tabs, toggles                                                                 |

The `data-test-jn-*` attributes are public API. They're documented in the Testing guide and
render in production, as Formwright's `data-test-fw-*` do.

### Styling pipeline

- `packages/ember/src/styles/<component>.css` holds `@apply` rules seeded with shadcn's class
  strings. `scripts/extract-classes.mjs` pulls the strings out of the upstream `cn(...)` and
  `cva(...)` calls, both for the first port and to diff when upstream changes.
- The build compiles that with Tailwind v4 into `dist/joinery.css` (components, in
  `@layer joinery`), `dist/tokens.css` (the default neutral theme, light and `.dark`),
  `dist/themes/*.css` (shadcn's base colours: neutral, stone, zinc, gray, slate) and
  `dist/tailwind.css` (`@theme inline` mapping the tokens to utilities, for Tailwind apps).
- Apps without Tailwind import `tokens.css` and `joinery.css`. Tailwind apps also import
  `tailwind.css` and can override any part with `class`.

### Floating parts and layering

`primitives/anchor`: the Popover API (`popover="auto"` or `"manual"`) for the top layer, with
no portals needed. CSS anchor positioning (`anchor-name`, `position-try-fallbacks`) where
`CSS.supports` says so; otherwise `@floating-ui/dom` with offset, flip, shift, size and arrow.
The same module provides ember-primitives' floating-ui component and modifier. CI runs the
suite a second time with the fallback forced on.

### Harnesses

Formwright's model, generalized: a base `Harness` class with a live DOM lookup, `@child` and
`find()`. Child harnesses are created once, on first use, and cached.

```ts
import { DialogHarness, ButtonHarness, child } from '@ember-joinery/test-support'
import { form } from '@ember-joinery/formwright/test-support'

class EditProfile extends DialogHarness {
  static named = 'edit-profile'
  @child(ButtonHarness, 'save') declare save: ButtonHarness
  @form(ProfileForm) declare profile: ProfileForm // a Formwright FormHarness
}

const dialog = new EditProfile()
await dialog.open()
await dialog.profile.name.fillIn('Ada')
await dialog.save.click()
assert.false(dialog.isOpen) // read from aria-expanded and <dialog open>
assert.dom(dialog.trigger).isFocused() // focus returned
await dialog.find(ButtonHarness, 'cancel') // a one-off lookup
```

Each harness checks it is pointed at the right component, reads state through ARIA (so every
test also checks the ARIA contract), and drives the component the way a user does: clicks,
keys and typing. Overlays follow `data-test-jn-owner` into the top layer. The library's own test
suite is written on the harnesses, which is how the harnesses get tested.

## Inventory

### shadcn/ui components (67 on ui.shadcn.com/docs/components)

| Phase       | Components                                                                                                                                                                          | Package                            |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| 3 Display   | Button, Badge, Alert, Card, Separator, Skeleton, Spinner, Kbd, Label, Aspect Ratio, Avatar, Typography, Empty, Item, Button Group, Table, Breadcrumb, Pagination, Progress          | ember                              |
| 4 Inputs    | Input, Textarea, Native Select, Checkbox, Radio Group, Switch, Slider, Toggle, Toggle Group, Input OTP, Input Group, Field                                                          | ember                              |
| 5 Overlays  | Dialog, Alert Dialog, Sheet, Drawer, Popover, Tooltip, Hover Card, Toast and Sonner (one Toast with sonner's `toast()` / `<Toaster>` API; both guide pages), Collapsible, Accordion | ember                              |
| 6 Menus     | Dropdown Menu, Context Menu, Menubar, Navigation Menu, Select, Combobox, Command, Tabs                                                                                              | ember                              |
| 7 Dates     | Calendar, Date Picker (single, range, presets)                                                                                                                                      | ember                              |
| 8 App shell | Sidebar, Resizable, Scroll Area, Direction                                                                                                                                          | ember                              |
| 9 Add-ons   | Carousel · Data Table · Code Block                                                                                                                                                  | carousel · data-table · code-block |
| 10 Charts   | Chart (area, bar, line, pie, radar, radial, with tooltip, legend and config)                                                                                                        | chart                              |
| 11 Chat     | Message, Bubble, Attachment, Marker, Message Scroller, Questionnaire, Trace                                                                                                         | ember                              |
| 12 Forms    | Form (shadcn's react-hook-form `Form` becomes Formwright)                                                                                                                           | formwright                         |

That is 67 docs pages: Toast and Sonner are two pages for one component.

### ember-primitives parity (each item goes in `@ember-joinery/primitives` unless noted)

| ember-primitives                                                                                                                                                                        | Joinery                                                                                 | Phase               |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- | ------------------- |
| Accordion, Avatar, Breadcrumb, Dialog/Modal, Drawer, Menu, Popover, Progress, Separator, Slider (range, multiple thumbs), Switch, Tabs, Toggle, ToggleGroup, OTP, Resizable/panel-group | The headless part under the matching shadcn component                                   | with that component |
| CommandPalette                                                                                                                                                                          | Command plus `CommandDialog`                                                            | 6                   |
| Rating (half ratings)                                                                                                                                                                   | Rating, plus a styled `Rating` in ember                                                 | 4                   |
| FileDrop, DocumentFileDrop                                                                                                                                                              | FileDrop, plus a styled drop zone in ember                                              | 4                   |
| Form (`dataFrom` FormData)                                                                                                                                                              | `NativeForm` (renamed so it can't clash with Formwright's `<Form>`; see the open items) | 4                   |
| floating-ui component, modifier and middleware                                                                                                                                          | `primitives/anchor`                                                                     | 2                   |
| Portal, PortalTargets                                                                                                                                                                   | `primitives/portal` (top layer first; portals for the cases that need them)             | 2                   |
| VisuallyHidden, Key/KeyCombo, color-scheme, tabster (focus)                                                                                                                             | `primitives/visually-hidden`, `/keys`, `/color-scheme`, `/focus`                        | 2                   |
| Scroller, Zoetrope, Hero, StickyFooter, Link (active-aware), ExternalLink, Heading (heading level), IncrementalEach, Shadowed                                                           | Components, with styled versions where shadcn has a counterpart                         | 8                   |
| head, qp, service, store, body-class, link helper, proper-links, iframe, load, InViewport/viewport, on-resize/resize-observer, dom-context, narrowing/type utils                        | One subpath export each (`primitives/head`, `/qp`, …)                                   | 8                   |
| test-support (a11y, dom, otp, rating, routing, zoetrope)                                                                                                                                | Folded into `@ember-joinery/test-support`                                               | with each feature   |

### React-only dependencies replaced

| Upstream dependency                                                     | Joinery                                                                           |
| ----------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| radix-ui                                                                | `@ember-joinery/primitives`                                                       |
| class-variance-authority, `cn`                                          | Typed `@variant`/`@size` args and data attributes; classes compiled at build time |
| lucide-react                                                            | `lucide` (framework-agnostic), imported per icon, plus `<Icon>`                   |
| cmdk, vaul, sonner, input-otp, react-resizable-panels, react-day-picker | Written in primitives and ember                                                   |
| embla-carousel-react                                                    | `embla-carousel` in `@ember-joinery/carousel`                                     |
| @tanstack/react-table                                                   | `@tanstack/table-core` in `@ember-joinery/data-table`                             |
| recharts                                                                | `@ember-joinery/chart` (Glimmer SVG on d3)                                        |
| react-hook-form (Form)                                                  | Formwright, via `@ember-joinery/formwright`                                       |
| next-themes                                                             | `primitives/color-scheme`                                                         |

### Size

8 packages; ~67 shadcn components, ~15 components only ember-primitives has, ~20 utilities;
~95 harness classes. Upstream has 244 example files, 71 chart examples and 27 blocks (we
port 4). Every ported example becomes a guide example with its own harness test and axe audit,
so about 320 example tests, plus the integration suite.

## Definition of done for every component

1. If it has behaviour, the primitive exists in `primitives`, with integration tests.
2. The styled component is in `.gts` with a Glint signature, the attributes listed above, its
   CSS ported from upstream, and RTL handled.
3. **Its harness** is in `test-support` (or the add-on's `/test-support`), and the component's
   own tests are written with it.
4. Tests cover rendering, controlled and uncontrolled state, the APG keyboard pattern, focus
   management, RTL and an axe audit, on Ember 7.3 and 6.12.
5. Its guide page has every upstream example for the component, each tested with the harness.
6. Each upstream example is mapped in `parity/map.json`, and the screenshot comparison passes in
   light and dark.
7. A changeset, and `docs/site/` updated wherever the site shows the component.

## Guide (`docs-app/`, Kolay)

- **Sections:** Getting started (Introduction, Installation for Vite, classic and Tailwind apps;
  Theming; Dark mode; RTL; Testing) · Components (A–Z, like ui.shadcn.com) · Primitives (headless
  use and the utilities) · Charts · Blocks · Formwright · Reference (`<APIDocs>`).
- **A component page:** a preview, installation and import, usage, Examples (each upstream
  example in Formwright's `<Example>` frame with Preview, Template and Test tabs), API (args,
  yields and data attributes for each part), keyboard interactions, accessibility, Testing (the
  component's harness members), and Upstream (a link to the shadcn page and the pinned commit).
- **The example frame**, as in Formwright, plus a theme switcher (base colour, radius,
  light/dark), an RTL toggle, and width presets (375, 768, 1440).
- **Theme builder page:** edit the tokens, watch every component update live, and copy the CSS.
- Every page is listed in `PAGES` in the acceptance test, and every example has
  `docs-app/tests/examples/<name>-test.gts`, written with harnesses and ending in an axe audit.

## Marketing site and demo

`docs/site/index.html` is hand-written and styled with Joinery's own `tokens.css` and
`joinery.css`. Sections: a hero (with the dovetail logo), why Joinery, install, usage, theming,
a component grid (screenshots made by `site-screenshots.mjs`), testing with harnesses,
Formwright, the live demo (`test-app` built into `docs/site/demo/`: the dashboard and settings
blocks), the guide, and siblings (Formwright, real-enums). The footer credits shadcn/ui and
ember-primitives. `pages.yml` builds the demo and guide, then deploys `docs/site`.

## Parity and upstream watch

- **Reference app** (`parity/`, private): a React 19 + Tailwind 4 Vite app that renders shadcn's
  `new-york-v4` `ui/` and `examples/` from the commit pinned in `upstream.json`. `parity.mjs
fetch` downloads them into a gitignored `parity/.upstream/`.
- **Joinery side:** docs-app has a `/parity/<id>` route that renders one example with no frame.
- **Comparison** (`scripts/parity.mjs`, the `parity.yml` workflow): pinned Playwright Chromium,
  fixed viewport, fonts loaded, animations off. Both sides are screenshotted in light and dark and
  diffed with pixelmatch. The check fails over a threshold (1% of pixels by default; an override
  for an example needs a written reason in `parity/map.json`), and a side-by-side report is
  uploaded. An upstream example missing from the map also fails, which keeps coverage complete.
- **Upstream watch** (`scripts/upstream.mjs`, a weekly `upstream.yml`): lists upstream changes
  since the pinned shas in shadcn's `registry/new-york-v4/{ui,examples,charts,blocks}` and
  `ember-primitives/src`, mapped to Joinery components, plus new upstream components, and updates
  one tracking issue. A sync PR ports the changes and bumps `upstream.json`.

## Phases (one PR each; the gate passes on every one; each publishes a 0.x minor)

### Phase 0: Bootstrap

- Create the public repo `joegaudet/ember-joinery` with `gh`, and Joe claims the npm org
  `@ember-joinery` (the npm website is the only way to create one). **Publishing waits on the org.**
- First PR: this plan, README stub, `LICENSE.md` (MIT), `NOTICE` (crediting shadcn/ui and
  ember-primitives), `CONTRIBUTING.md`, and `CLAUDE.md`. CLAUDE.md carries Formwright's rules
  (keep the site in sync, keep the guide in sync) plus two of Joinery's own: every component
  ships with its harness and parity mapping, and `upstream.json` moves only in sync PRs.

### Phase 1: Monorepo, tooling, CI

- Formwright's setup, copied and renamed: pnpm workspace, `useNodeVersion` 24, flat ESLint,
  Prettier with the template-tag plugin, TypeScript 6, Glint, `@embroider/addon-dev` + rollup, and
  Formwright's Kolay workarounds (ember-repl patch, `@glint/template` override, `keepNames`).
- Package skeletons for `primitives`, `ember` and `test-support`. The CSS build pipeline (Tailwind
  v4 to `dist/*.css`). `test-app`, a `docs-app` shell with the `<Example>` frame, the site shell,
  and the four example apps.
- The harness base (`Harness`, `@child`, `find`, owner-following, the selector reference), with
  tests. `extract-classes.mjs`, `upstream.mjs`, the parity reference app and `parity.mjs`, with
  `node --test` coverage.
- Workflows: `ci` (static; tests on 7.3 and 6.12; a second run with the anchor fallback forced;
  guide; examples), `parity`, `upstream`, `pages`, `release`, `bootstrap-publish`.

### Phase 2: Primitives foundation

The controllable-state helper; ids; Direction; Portal and PortalTargets; layering (the Popover
API); `anchor` (CSS anchor positioning plus floating-ui); a dismiss stack (Escape, outside
click, nested layers); focus scope and trap; roving focus; typeahead; presence (exit
animations driven by `data-state`); the `@as` + yielded-modifier pattern; VisuallyHidden;
Key/KeyCombo; color-scheme. Each one gets integration tests, and a harness where it is visible.

### Phase 3: Theme and display components (first publish: 0.1.0)

`tokens.css`, the base-colour themes, `tailwind.css`, and `<Icon>`. The 19 display components
listed above. The guide's theme switcher, RTL toggle and width presets go in here, because
every later page uses them. The first publish of each new package goes out through
`bootstrap-publish.yml`; after that, OIDC trusted publishing takes over.

### Phase 4: Inputs

The 12 input components, plus Rating, FileDrop and `NativeForm`. Each standalone control takes
`@value` and `@onValueChange` (Formwright comes in Phase 12).

### Phase 5: Overlays

Dialog, Alert Dialog, Sheet, Drawer (drag to dismiss, snap points, scaled background, as in
vaul), Popover, Tooltip, Hover Card, Toast (stacking, swipe, promise toasts, as in sonner),
Collapsible and Accordion.

### Phase 6: Menus, selection, navigation

Dropdown Menu, Context Menu, Menubar and Navigation Menu (submenus, checkbox and radio items,
typeahead, pointer grace areas). Select, Combobox, Command plus `CommandDialog`, and Tabs.
This is the heaviest phase and may split into 6a (menus) and 6b (selection and Tabs).

### Phase 7: Dates

Calendar (single, multiple and range; month and year dropdowns; locale-aware week start; RTL)
and Date Picker (popover, range, presets).

### Phase 8: App shell and utilities

Sidebar (collapsible: offcanvas, icon and none; mobile sheet; a keyboard shortcut; persisted
state), Resizable, Scroll Area and Direction. ember-primitives' Scroller, Zoetrope, Hero,
StickyFooter, Link, ExternalLink, Heading, IncrementalEach and Shadowed. All the app utilities
(head, qp, service/store, body-class, proper-links, iframe, load, InViewport, resize).

### Phase 9: Carousel, Data Table, Code Block

Each in its own package, with its example app in CI.

### Phase 10: Charts

`@ember-joinery/chart`: a container with config and `--chart-N` colours, tooltip and legend,
and area, bar, line, pie, radar and radial charts. All 71 upstream chart examples.

### Phase 11: Chat components

Message, Bubble, Attachment, Marker, Message Scroller (anchoring to turns, following a stream,
loading history without jumping, jumping to a message), Questionnaire and Trace. These use Code
Block from Phase 9.

### Phase 12: Formwright bridge

`@ember-joinery/formwright`: every Joinery input registered as a Formwright control, a Field
layout using shadcn's Field anatomy, and harnesses built on Formwright's `FieldHarness`. The 34
upstream `form-*` examples are rebuilt on Formwright. There is an `ember-formwright` example app.

### Phase 13: Blocks, demo, site, theme builder, reference

Login, signup, dashboard with sidebar, and settings as guide examples and in the demo. The
finished marketing site, the social card, the theme builder page, and `<APIDocs>` reference
pages.

### Phase 14: 1.0

A parity audit: every upstream example is mapped and passing. A last upstream sync. PRs to
ember-formwright and real-enums for the cross-links. 1.0.0 published with release notes.

## The gate (CONTRIBUTING.md)

```bash
pnpm format:check
pnpm build
pnpm lint
pnpm typecheck
node --test scripts/*.test.mjs
pnpm test                          # test-app, Ember 7.3
pnpm --filter docs-app test        # every guide example and page
pnpm test:examples                 # vite-basic, classic, tailwind, formwright
pnpm parity                        # screenshot comparison (CI: parity.yml)
```

As in Formwright, CI also runs the suite on 6.12 by overriding `ember-source` for the whole
workspace.

## Risks and open items

- **The `@ember-joinery` npm org.** The names `ember-joinery` and `@ember-joinery/ember` were
  unclaimed on 2026-11-08, but I couldn't check the org itself. This blocks Phase 0.
- **ui.shadcn.com does not resolve from Claude's cloud sessions.** Everything here comes from
  its GitHub source, and parity runs in GitHub Actions, which needs no access to the site. If you
  want sessions to read the live site, add `ui.shadcn.com` to the environment's allowed hosts.
- **Size.** Roughly 320 example tests and ~95 harnesses. Upstream's examples serve as the spec;
  big phases split into a/b PRs rather than growing past review size.
- **Pixel noise.** Fonts, anti-aliasing, animations, and whitespace differences between React
  and Glimmer DOM can trip the comparison. One pinned browser and font set, a threshold, and
  written reasons for each override.
- **Upstream moves fast.** The chat set arrived in 2026, and shadcn now also ships Base UI and
  React Aria variants. Joinery tracks Radix `new-york-v4` only.
- **Hardest behaviours.** Each gets a spike at the start of its phase: Drawer gestures, Navigation
  Menu motion, the menus' pointer grace areas, Message Scroller anchoring, chart tooltips and
  animation.
- **Naming.** shadcn's `Form` (react-hook-form), ember-primitives' FormData `Form` and
  Formwright's `<Form>` collide. Proposal: Formwright supplies `Form`, and the FormData helper
  becomes `NativeForm`.
- **Toasts outside components.** sonner's module-level `toast()` needs owner-scoped state for test
  isolation: `toast` resolves the app's Toaster through the owner, and test-support provides a
  `setupToaster(hooks)` helper.
- Classic apps need ember-auto-import ≥ 2 to consume `.gts` v2 addons; the classic example proves it.

## Next steps

1. Review this plan in Phase 0's PR. Any decision can still change there.
2. Phase 1 (monorepo, tooling, CI) starts once that PR is merged.
