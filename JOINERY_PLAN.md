# Joinery: shadcn/ui for Ember, as a Formwright sibling

Status: building (2026-11-08). The plan was agreed through a 40-question intake. It is being built
unattended by subagents onto one stacked PR; see "Autonomous execution".

Deviations from the intake, and why:

- **One stacked PR, built unattended** (replaces decisions 8 and 38). Joe asked for subagents to
  work through everything without feedback, as one big stacked PR. Each unit lands as its own
  commits on `build/joinery-1.0`. Nothing merges to `main` and nothing publishes until Joe has
  reviewed the whole PR.
- **The upstream source, corrected.** ui.shadcn.com no longer renders the `new-york-v4` registry.
  Its component pages render `apps/v4/registry/bases/radix/ui`, styled by one of eight style
  sheets (`apps/v4/registry/styles/style-*.css`, Nova by default), with examples from
  `apps/v4/examples/radix/`. Joinery ports that, so the scope is the 497 examples the docs pages
  reference (501 previews: `button-group-demo`, `card-rtl` and `field-demo` each show on two pages,
  and the Hover Card page shows `hover-card-demo` twice), not new-york-v4's 244. Charts
  still come from `registry/new-york-v4/charts` (the charts gallery), and blocks from
  `registry/bases/radix/blocks`.
- **All eight shadcn styles.** Upstream's components now carry semantic classes (`cn-button`,
  `cn-button-variant-outline`) that each style sheet defines with `@apply`. Joinery ports the
  sheets mechanically (`cn-` becomes `jn-`), so it ships Nova as the default and the other seven
  (Luma, Lyra, Maia, Mira, Rhea, Sera, Vega) as alternatives, and the guide's theme switcher
  offers all of them.
- **The base colours, corrected.** At the pinned commit, upstream's base colours
  (`registry/base-colors.ts`) are Neutral, Stone, Zinc, Mauve, Olive, Mist and Taupe; Gray and
  Slate are gone. Joinery ships those seven, ported from `registry/themes.ts`.
- **Clarified while building** (no decision changed). The generated `meta.json` covers every
  A–Z section of the guide (Components, Primitives, Charts, Blocks, Formwright and Reference),
  not only Components. The Guide section now says what "Autonomous execution" already did: the
  acceptance test builds `PAGES` from the templates directory. And setting the repository's
  Pages source to GitHub Actions, which `pages.yml` needs, is listed among what stays with Joe.

**What we're copying:** [ui.shadcn.com](https://ui.shadcn.com/): every component, every example
on its component pages, a subset of its blocks, and its theming. The source of truth is the code
that builds that site, `shadcn-ui/ui` `apps/v4/` (components in `registry/bases/radix`, styles in
`registry/styles`, examples in `examples/radix`), pinned at
`8ab2771` (2026-11-08). Joinery also covers every feature of
[ember-primitives](https://github.com/universal-ember/ember-primitives) 0.64.2 (`9584c78`).
Both are MIT.

Joinery follows the Formwright methodology: v2 addons in a pnpm monorepo, strict TypeScript and
Glint, `.gts` everywhere, a harness class for every component, a Kolay guide whose examples
are all tested, a hand-written marketing site with a live demo, Changesets, and tag-triggered
OIDC releases.

## Decisions (from intake)

| #   | Area            | Decision                                                                                                                                                                                  |
| --- | --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Name            | **Joinery**. Repo `joegaudet/ember-joinery`, npm `@ember-joinery/*`                                                                                                                       |
| 2   | Distribution    | npm v2 addons only; no copy-in CLI                                                                                                                                                        |
| 3   | Packages        | Core plus opt-in add-ons, one add-on per heavy dependency                                                                                                                                 |
| 4   | Positioning     | Its own brand. "Design and API ported from shadcn/ui (MIT)" in the README, the site footer and `NOTICE`                                                                                   |
| 5   | Primitives      | Our own headless `@ember-joinery/primitives`, covering all of ember-primitives plus the Radix parts shadcn needs. No ember-primitives dependency                                          |
| 6   | Repo            | `joegaudet/ember-joinery`, public, created with `gh` from Joe's machine                                                                                                                   |
| 7   | Plan            | This file, committed as `JOINERY_PLAN.md` in the repo's first PR                                                                                                                          |
| 8   | Process         | One stacked PR on `build/joinery-1.0`, built unattended by subagents (see the deviations above); Joe reviews and merges it at the end                                                     |
| 9   | Ember           | 7.3 (latest) and 6.12 (previous LTS), both in CI                                                                                                                                          |
| 10  | Consumers       | Vite/Embroider and classic ember-cli apps, each with an example app in CI                                                                                                                 |
| 11  | Composition     | Yielded parts: `<Dialog as \|d\|><d.Trigger>…</d.Trigger><d.Content>…`                                                                                                                    |
| 12  | State           | Controlled or uncontrolled, as in Radix: `@open`/`@defaultOpen`/`@onOpenChange`, `@value`/`@defaultValue`/`@onValueChange`                                                                |
| 13  | Styling         | shadcn's style sheets ported with `cn-*` renamed `jn-*`, compiled with Tailwind v4, and shipped as plain CSS on those semantic classes in `@layer joinery`. Tailwind is optional for apps |
| 14  | Tokens          | shadcn's names in OKLCH (`--background`, `--primary`, `--ring`, `--radius`, `--chart-1..5`, `--sidebar-*`…), so any shadcn theme pastes in unchanged                                      |
| 15  | Variants        | Typed `@variant` and `@size` args, rendered as `data-variant` and `data-size`                                                                                                             |
| 16  | Dark mode       | A `.dark` class, plus a color-scheme utility (follows the OS, saves the choice, syncs tabs)                                                                                               |
| 17  | Floating parts  | The Popover API for layering. CSS anchor positioning where the browser has it, `@floating-ui/dom` otherwise. Supported: the last 2 versions of evergreen browsers                         |
| 18  | `asChild`       | An `@as` tag, plus a yielded modifier for each part that needs one, e.g. `<LinkTo {{d.trigger}}>`                                                                                         |
| 19  | Accessibility   | WCAG 2.2 AA: an axe audit in every test, plus APG keyboard and focus tests for each component                                                                                             |
| 20  | i18n            | RTL: logical properties, a Direction provider, arrow keys flip. Every built-in string is an arg with an English default                                                                   |
| 21  | Scope           | All ~67 shadcn components, the chat set included, plus every ember-primitives component                                                                                                   |
| 22  | Utilities       | ember-primitives' non-visual utilities go in `@ember-joinery/primitives`, one subpath export per feature                                                                                  |
| 23  | Heavy deps      | We write Command, Drawer, Toast, Resizable, OTP and Calendar ourselves. Add-ons wrap embla-carousel, `@tanstack/table-core`, shiki and d3                                                 |
| 24  | Charts          | Declarative Glimmer SVG on `d3-scale` and `d3-shape`, with an API shaped like recharts                                                                                                    |
| 25  | Formwright      | `@ember-joinery/formwright`: Joinery controls as Formwright controls, a Field-anatomy layout, and harnesses                                                                               |
| 26  | Icons           | Lucide (the framework-agnostic `lucide` package), imported per icon. Apps get `<Icon>`, and every icon slot can be replaced                                                               |
| 27  | Blocks          | Login, signup, dashboard with sidebar, and settings, as tested guide examples and in the demo (not exported)                                                                              |
| 28  | Dates           | `Date` in and out (`{ from, to }` for ranges), formatted with `Intl`; no date library                                                                                                     |
| 29  | Harness pkg     | `@ember-joinery/test-support`; each add-on exports its own harnesses from a `/test-support` subpath                                                                                       |
| 30  | Harness lookup  | `data-test-jn-*` attributes find and scope; state is read through ARIA                                                                                                                    |
| 31  | Harness compose | Formwright-style decorators (`@child`, `@form`) plus `find()` for one-off lookups. Portalled content is followed through its owner id                                                     |
| 32  | Runners         | `@ember/test-helpers` (QUnit or Vitest)                                                                                                                                                   |
| 33  | Site CSS        | Hand-written HTML styled with Joinery's own compiled CSS (no Pico)                                                                                                                        |
| 34  | Guide           | One page per component, laid out like ui.shadcn.com's                                                                                                                                     |
| 35  | Guide extras    | Theme switcher, RTL and width toggles, a theme builder page, generated API reference                                                                                                      |
| 36  | Brand           | The sibling layout and type of Formwright and real-enums, with its own accent and logo (a dovetail mark)                                                                                  |
| 37  | Release         | Formwright's machinery: Changesets with all packages versioned together, a version PR from the GitHub App, a release on a pushed tag (OIDC), and `bootstrap-publish.yml`                  |
| 38  | Versions        | Nothing publishes during the build. After Joe merges, the changesets that have built up become 1.0.0, released through the bootstrap workflow for each new package                        |
| 39  | Siblings        | PRs to ember-formwright and real-enums adding Joinery to their sibling lists, and a pointer in Formwright's guide                                                                         |
| 40  | Fidelity        | CI compares screenshots with shadcn's own examples, in light and dark. An upstream watch lists what changed upstream since the last sync                                                  |

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
                   port-styles.mjs, extract-classes.mjs, site-screenshots.mjs, gen-barrels.mjs,
                   entrypoints.mjs, *.test.mjs
  upstream.json    the shadcn-ui/ui and ember-primitives commits last synced
  upstream/        inventory.json: every docs page's examples and their styles, the ui, charts, blocks
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

- `packages/ember/src/styles/<style>.css` holds shadcn's eight style sheets, ported by
  `scripts/port-styles.mjs`. The script renames `cn-` to `jn-` and makes physical sides logical
  (`pl-2` to `ps-2`, as upstream's right-to-left build does, so one sheet serves both
  directions), and otherwise keeps upstream's `@apply` rules verbatim, so upstream changes diff
  cleanly. Components render the same semantic
  classes upstream's do (`jn-button jn-button-variant-outline jn-button-size-sm`), plus the data
  attributes.
- Upstream also puts some utility classes inline in each component (`inline-flex`, `shrink-0`…).
  `scripts/extract-classes.mjs` pulls them out of the upstream `cn(...)` and `cva(...)` calls
  into rules that follow the style sheet's. Where a later class in upstream's class list (a
  variant, a size) overrides an inline one, the rule skips that class, so the cascade matches
  upstream's merge order.
- The build compiles all of that with Tailwind v4 into `dist/joinery.css` (the Nova style, in
  `@layer joinery`), `dist/styles/<style>.css` (the other seven), `dist/tokens.css` (the default
  neutral theme, light and `.dark`), `dist/themes/*.css` (shadcn's base colours: neutral, stone,
  zinc, mauve, olive, mist, taupe) and `dist/tailwind.css` (`@theme inline` mapping the tokens to
  utilities, for Tailwind apps).
- Apps without Tailwind import `tokens.css` and `joinery.css`. Tailwind apps also import
  `tailwind.css` and can override any part with `class`.

### Floating parts and layering

`primitives/layer`: the Popover API (`popover="auto"` or `"manual"`) for the top layer, with
no portals needed. `primitives/anchor`: CSS anchor positioning (`anchor-name`,
`position-try-fallbacks`) where `CSS.supports` says so; otherwise `@floating-ui/dom` with
offset, flip, shift, size and arrow. The same module provides ember-primitives' floating-ui
component, modifier and middleware. `primitives/dismiss`: the dismiss stack (Escape, pointers
and focus outside, nested layers), and `primitives/portal` for the cases that need a portal. CI
runs the suite a second time with the fallback forced on.

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
~95 harness classes. The docs pages reference 497 examples, the charts gallery has 70, and we
port 4 of the 27 blocks. Every ported example becomes a guide example with its own harness test
and axe audit, so about 570 example tests, plus the integration suite. `--require-complete`
expects all 567 docs examples and charts in the parity map (`upstream/inventory.json` has the
current counts).

## Definition of done for every component

1. If it has behaviour, the primitive exists in `primitives`, with integration tests.
2. The styled component is in `.gts` with a Glint signature, the attributes listed above, its
   CSS ported from upstream, and RTL handled.
3. **Its harness** is in `test-support` (or the add-on's `/test-support`), and the component's
   own tests are written with it.
4. Tests cover rendering, controlled and uncontrolled state, the APG keyboard pattern, focus
   management, RTL and an axe audit, on Ember 7.3 and 6.12.
5. Its guide page has every upstream example for the component, each tested with the harness.
6. Each upstream example is mapped in `parity/map/<component>.json`, and the screenshot
   comparison passes in light and dark.
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
  light/dark), an RTL toggle, and width presets (375, 768, 1440). `@dir="rtl"` shows one of
  upstream's right-to-left (`*-rtl`) examples, as the parity route's `?dir=rtl` does.
- **Theme builder page:** edit the tokens, watch every component update live, and copy the CSS.
- The acceptance test renders every page (its `PAGES` come from the templates directory), and
  every example has `docs-app/tests/examples/<name>-test.gts`, written with harnesses and ending
  in an axe audit.

## Marketing site and demo

`docs/site/index.html` is hand-written and styled with Joinery's own `tokens.css` and
`joinery.css`. Sections: a hero (with the dovetail logo), why Joinery, install, usage, theming,
a component grid (screenshots made by `site-screenshots.mjs`), testing with harnesses,
Formwright, the live demo (`test-app` built into `docs/site/demo/`: the dashboard and settings
blocks), the guide, and siblings (Formwright, real-enums). The footer credits shadcn/ui and
ember-primitives. `pages.yml` builds the demo and guide, then deploys `docs/site`.

## Parity and upstream watch

- **Reference app** (`parity/`, private, its own pnpm workspace): a React 19 + Tailwind 4 Vite
  app that renders shadcn's `registry/bases/radix/ui` and `examples/radix/`, each example in the
  style its docs page uses (charts from `registry/new-york-v4/charts`), from the commit pinned in
  `upstream.json`. `upstream.mjs fetch` downloads them into a gitignored `.upstream/`, and the
  app generates upstream's `styles/<style>/ui` from them with the published `shadcn` package's
  transforms, as upstream's registry build does.
- **Joinery side:** docs-app has a `/parity/<id>` route that renders one example with no frame.
- **Comparison** (`scripts/parity.mjs`, the `parity.yml` workflow): pinned Playwright Chromium,
  fixed viewport, fonts loaded, animations off. Both sides are screenshotted in light and dark and
  diffed with pixelmatch, over the content's bounding box rather than the whole page. The check
  fails over a threshold (1% of the box's pixels by default; an override
  for an example needs a written reason in `parity/map/<component>.json`), and a side-by-side report is
  uploaded. With `--require-complete`, an upstream example missing from the map also fails, which
  keeps coverage complete. CI turns that flag on for the final unit; until then, the check covers
  the examples that are mapped.
- **Upstream watch** (`scripts/upstream.mjs changes`, a weekly `upstream.yml`): lists upstream
  changes since the pinned shas in shadcn's `registry/bases/radix/{ui,blocks}`, `registry/styles`
  (down to the rules that changed), `examples/radix`, `registry/new-york-v4/charts`, its docs
  pages, `packages/react` (the chat set's headless parts), and `ember-primitives/src`, mapped to
  Joinery components, plus new upstream components, and updates one tracking issue. A sync PR
  ports the changes and bumps `upstream.json`.

## Phases (the order of the work; each phase is a group of units in the stacked PR)

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

### Phase 3: Theme and display components

`tokens.css`, the base-colour themes, `tailwind.css`, and `<Icon>`. The 19 display components
listed above. The guide's theme switcher, RTL toggle and width presets go in here, because
every later page uses them. Nothing publishes during the build (see "Autonomous execution").

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

Each in its own package, with its example app in CI. Carousel's headless part, the `{{embla}}`
modifier, ships in `@ember-joinery/carousel` rather than as a primitive, so `primitives` takes no
Embla dependency.

### Phase 10: Charts

`@ember-joinery/chart`: a container with config and `--chart-N` colours, tooltip and legend,
and area, bar, line, pie, radar and radial charts. All 70 upstream chart examples.

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

A parity audit: every upstream example is mapped and passing with `--require-complete`. A last
upstream sync. The full gate, including the 6.12 run. PRs to ember-formwright and real-enums for
the cross-links (opened, not merged). Then the stacked PR is marked ready for review. Joe merges
it and releases 1.0.0.

## Autonomous execution

Joe asked for the whole plan to be built by subagents without feedback, as one big stacked PR.

- **One branch, one PR.** `build/joinery-1.0` starts from Phase 0 and backs a single draft PR
  into `main`. Each unit lands on it as its own commits, in dependency order, so the PR reads as
  a stack: review it commit by commit or unit by unit. Nothing merges to `main`, nothing
  publishes, and no tag is pushed until Joe has reviewed it.
- **Units.** The phases are split into about 48 units: one or a few related components, or one
  piece of tooling. The orchestrating workflow's unit list is the authoritative split, and each
  unit names its dependencies.
- **Per unit:**
  1. An implement agent works in its own worktree (`/home/user/jn-wt/<unit>`, branch
     `unit/<unit>`, cut from the integration branch).
  2. An independent review agent checks the result against the definition of done and the
     upstream examples. Up to two rounds of fixes follow.
  3. An integrate agent rebases the unit onto the integration branch, runs the gate,
     fast-forwards and pushes.

  Units integrate one at a time; implementation runs in parallel wherever the dependencies
  allow.

- **CI stays green.** Before integrating, the integrate agent checks GitHub CI on the branch tip
  and fixes any failure first. CI covers the 6.12 run, the anchor-fallback run and parity, which
  the local gate skips to save time.
- **Shared files don't collide.** Registries that every component touches are either one file per
  component or generated:
  - the package barrels (`src/index.ts`) and the test-support index are generated from the files
    present, by `scripts/gen-barrels.mjs` on every build (they are gitignored);
  - the `meta.json` of the guide's A–Z sections (Components, and likewise Primitives, Charts,
    Blocks, Formwright and Reference) is generated, in alphabetical order;
  - each component has its own `parity/map/<component>.json`;
  - the acceptance test's `PAGES` is built from the templates directory.

  Phase 1 sets all of these up.

- **No silent gaps.** A unit that can't meet an item of the definition of done lists it, with the
  reason, under "Known gaps" in the PR body. A unit that can't be built at all is reported as
  blocked, and the units that depend on it are skipped and reported. Everything else carries on.
- **Progress** is a checklist in the PR body, ticked as each unit integrates.
- **What stays with Joe:**
  - reviewing and merging the PR;
  - publishing: the npm-bootstrap environment's `NPM_TOKEN`, approving the bootstrap run,
    setting up trusted publishers, and pushing the tag;
  - required status checks on `main`;
  - setting the repository's Pages source to "GitHub Actions", so `pages.yml` can deploy;
  - merging the sibling PRs on ember-formwright and real-enums.

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

- **Upstream's colours and WCAG AA.** In shadcn's light themes, two of upstream's parts fall
  short of the 4.5:1 AA asks of small text: Kbd's keys (`--muted-foreground` on `--muted`, 3.9:1
  to 4.5:1 across the base colours) and the destructive Badge (`--destructive` on its own 10%
  tint, about 4:1). Joinery keeps upstream's colours, documents the CSS that meets AA on each
  page, and audits everything around those elements (see "Upstream's colours and AA" in
  CONTRIBUTING.md). Whether Joinery should darken them instead, at a cost in fidelity, is Joe's
  call.
- **Where Table and Progress part from upstream, for WCAG.** Upstream's Progress
  leaves its value off the Radix root, so it always reads as indeterminate; Joinery's announces
  it. Upstream's Table container scrolls a wide table with no way in from the keyboard; Joinery's
  joins the tab order while it scrolls and has nothing focusable. The pixels are upstream's.
  Like upstream's right-to-left copy, Progress fills from the left in both directions (its
  example adds `rtl:rotate-180`); filling from the inline start instead is Joe's call.
- **An unattended build at this scale.** About 150–200 agent runs over several days. On a 4-CPU
  machine, two agents run at a time. The workflow journal lets a restarted session resume where
  it stopped.
- **ui.shadcn.com does not resolve from Claude's cloud sessions.** Everything here comes from
  its GitHub source, and parity runs in GitHub Actions, which needs no access to the site. If you
  want sessions to read the live site, add `ui.shadcn.com` to the environment's allowed hosts.
- **Size.** About 570 example tests and ~95 harnesses. Upstream's examples serve as the spec, and
  big components split into several units.
- **Pixel noise.** Fonts, anti-aliasing, animations, and whitespace differences between React
  and Glimmer DOM can trip the comparison. One pinned browser and font set, a threshold, and
  written reasons for each override.
- **Upstream moves fast.** The chat set arrived in 2026, and shadcn now also ships Base UI and
  React Aria variants. Joinery tracks the Radix base and its eight styles only.
- **Hardest behaviours.** Each gets a spike at the start of its phase: Drawer gestures, Navigation
  Menu motion, the menus' pointer grace areas, Message Scroller anchoring, chart tooltips and
  animation.
- **Naming.** shadcn's `Form` (react-hook-form), ember-primitives' FormData `Form` and
  Formwright's `<Form>` collide. Proposal: Formwright supplies `Form`, and the FormData helper
  becomes `NativeForm`.
- **Toasts outside components.** sonner's module-level `toast()` needs owner-scoped state for test
  isolation: `toast` resolves the app's Toaster through the owner, and test-support provides a
  `setupToaster(hooks)` helper. Built so: the toasts are a per-owner service, `toast()` uses the
  owner of the newest rendered `<Toaster>`, and `setupToaster(hooks)` points it at each test's
  owner through `globalThis.JOINERY_TOAST_OWNER`, as `JOINERY_ANCHOR_FALLBACK` does for anchoring.
- Classic apps need ember-auto-import ≥ 2 to consume `.gts` v2 addons; the classic example proves it.

## Next steps

1. The workflow builds every unit onto `build/joinery-1.0`, ticking the PR's checklist as it goes.
2. When the last unit lands, the PR is marked ready for review. Joe reviews it, merges it, and
   releases 1.0.0.
