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
before any module runs. `@ember-joinery/primitives/anchor` reads that global each time it
anchors an element (not once at import), and uses Floating UI whenever it is `true`. A test
module can force the same with `setupAnchorFallback(hooks)` from `@ember-joinery/test-support`,
so tests that care can cover both ways in one run.

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

`@ember-joinery/ember` also builds its CSS: after every rollup build, `packages/ember/build-css.mjs`
compiles each style with the Tailwind v4 CLI, Nova into `dist/joinery.css` and the other seven
into `dist/styles/<style>.css`, and copies `dist/tokens.css` (the Neutral base colour),
`dist/themes/<colour>.css` and `dist/tailwind.css`. A style is `src/css/setup.css` (Tailwind's
theme, inlined, but for `font-sans` and `font-mono`, which read the page's `--font-sans` and
`--font-mono` first, as upstream's globals.css maps them; tw-animate-css, shadcn's own variants
and the token mapping, none of it emitted),
then, in `@layer joinery`, `src/css/base.css` (the radius scale, and the share of Tailwind's
preflight upstream's parts rely on, scoped to `[data-slot]`), the ported sheet, and every
component's own CSS (`src/components/**/*.css`, A–Z). The script writes that entry itself, so a
component's CSS file needs no list edited. Between the sheet and the components' CSS it puts the
`MERGED` rules (listed in the script): where upstream gives one element two semantic classes
and its tailwind-merge lets the earlier rule's utilities beat the later's (a Navigation Menu
link with `navigationMenuTriggerStyle()` takes the trigger's padding), the winning class's rule
from that style's sheet is repeated for an element with both. Everything it ships is in that layer, but for what
Tailwind emits for the rules to use (`@property` registrations, keyframes, `@layer
properties`): the build fails on any other unlayered rule, which would beat an app's own
layered CSS (it drops the one shadcn's `tailwind.css` keeps for a bare `.shimmer` class). In
watch mode (`pnpm start` in the package), editing any CSS file under `src/` rebuilds them.

An add-on (`packages/code-block`, `packages/carousel`, `packages/chart`, `packages/file-upload`,
`packages/data-table`, `packages/tiptap` and `packages/power-calendar`) is a v2 addon like
`ember`, built with the same rollup config, around the heavy dependency it wraps (Shiki for Code
Block, Embla for Carousel, d3's scales and shapes for Chart, ember-file-upload for File Upload,
TanStack Table's `@tanstack/table-core` for Data Table, Tiptap for Rich Text Editor,
ember-power-calendar for Power Calendar). Its harnesses are in `src/test-support/`, a barrel of
their own and its
`/test-support` subpath (`"barrels": ["src", "src/test-support"]`), and it takes
`@ember-joinery/ember` and `@ember-joinery/test-support` as peers. It ships no CSS: upstream's
style sheets, which `ember` ports whole, already style its parts, so its inline utilities go in
`packages/ember/src/components/<name>.css` like any component's, and `joinery.css` styles the
add-on with nothing more to import. An add-on on one of Formwright's libraries (File Upload, on
ember-file-upload; Rich Text Editor, on Tiptap; Power Calendar, on ember-power-calendar) has no
upstream counterpart: its parts borrow the nearest shadcn components' classes, or render those
components (the Rich Text Editor's Input Group, Toggle Groups and Dropdown Menu; Power Calendar
draws shadcn's Calendar, and its rules are calendar.tsx's inline utilities), and its own rules
go in that file all the same (`file-upload.css`, `rich-text-editor.css`, `power-calendar.css`).
Nothing in the core packages imports an add-on or lists its library.

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
   `@ember-joinery/ember`, and the harness in `@ember-joinery/test-support`. Build the
   behaviour from the primitives' foundations: `controllable()` for state the caller may
   control (`@open`, `@defaultOpen`, `@onOpenChange`), `idFor()` for the ids ARIA ties
   together, `part()` and `As` for each part a caller may render as their own element (`@as`,
   `<LinkTo {{d.trigger}}>`), `Presence` for a part that animates out, and `getDirection()`
   wherever the text direction matters. The guide's Primitives section shows each.
   For focus: `{{focusScope}}` (or `createFocusScope()`) for a part that takes focus in, can
   trap it and gives it back, `RovingFocus` for items the arrow keys move between, `Typeahead`
   and `getNextMatch()` for typing to an item, and `focusable` and `{{restoreFocus}}` for
   finding focus a place. Test them with `tab()`, `pressKey()` and `typeKeys()` from
   `@ember-joinery/test-support`: a test can't press the real Tab key.
   For overlays: `{{topLayer}}` for a part that shows above everything, `{{anchorTo}}` (or
   `FloatingUI`) to place it against its trigger, `{{dismissable}}` to close it on Escape or a
   press or focus outside (with its trigger in `inside`), and `Portal` only where a part must
   render somewhere else. Test them with `press()`, `pressOutside()` and `pressEscape()`:
   `click()` sends no `pointerdown`, which the dismiss stack listens for. For a drag (a
   Resizable handle, a Scroll Area thumb), `sendPointer()` sends real `PointerEvent`s, which
   `triggerEvent()` doesn't; a harness that drags takes distances in CSS pixels, since the test
   container's scale makes the pointer's pixels differ. A modal part also
   makes the rest of the page inert (`inertOthers()`) and locks its scroll (`{{scrollLock}}`);
   a part that is a dialog (a Drawer, Command's dialog) builds on
   `@ember-joinery/primitives/dialog`, which does all of this.
   For a native control (`<input>`, `<textarea>`, `<select>`): `{{nativeValue}}`, which gives
   it `@value`, `@defaultValue` and `@onValueChange`, as Input, Textarea and Native Select have.
3. Its styles come from the ported style sheets, `packages/ember/src/styles/<style>.css`, which
   `node scripts/port-styles.mjs` writes from upstream's (it renames `cn-` to `jn-`, drops the
   `.style-<name>` wrapper, puts each selector in `:where()`, and makes physical sides logical,
   `pl-2` to `ps-2`, as upstream's right-to-left build does, so one sheet serves both
   directions; don't edit them by hand). The same script writes the base colours,
   `packages/ember/src/themes/<colour>.css`, from upstream's `registry/themes.ts`. Upstream also
   writes utility classes inline in the component. For those, run
   `node scripts/extract-classes.mjs <name> --out packages/ember/src/components/<name>.css`: it
   writes them as `@apply` rules, which the build puts after the style sheet's rules. Keep its
   output whole, because the order is upstream's. A class Tailwind has no utility for
   (navigation-menu's `origin-top-center`) styles nothing on ui.shadcn.com and would fail
   `@apply`, so the script asks Tailwind, set up as the build is, and leaves each such class out
   under a `NOTE`. Upstream's
   registry build (shadcn's `transformStyle`) swaps each semantic class for its style rule's
   utilities, and of two conflicting classes the later wins. Where the rule's utilities land
   depends on the call:
   - In a `cva()`, each string is swapped in place (its rule, then its inline utilities), and the
     strings run base, then variants. So an inline utility beats its own class's rule but loses
     to a later variant's: Badge's inline `focus-visible:ring-ring/50` loses to the ring colour
     in `jn-badge-variant-destructive`. The script checks each inline utility against the later
     strings' rules in all eight sheets. When a later class overrides it, the script moves it to
     a rule that skips that class (`:where(.jn-badge:not(.jn-badge-variant-destructive))`), and a
     `NOTE` marks any case this can't express.
   - A `cn()` call gathers the semantic classes of all its plain string arguments and puts their
     rules at the front of the call, so every inline utility in it beats all of them, a later
     argument's included. Where the first argument isn't a plain string
     (`cn(buttonVariants(…), "cn-x …")`), the rules go ahead of it too, and a `NOTE` says so.
   - Some semantic classes are never swapped, so ui.shadcn.com never styles them: those behind a
     condition (`open && "cn-x"`), in a `cn()` call that isn't a `className` (Calendar's
     `classNames={{…}}`, Input OTP's `containerClassName`), and in a cva compound variant. A
     `NOTE` marks each one; to match upstream, keep that class off the element. A
     `<part>ClassName` prop's rule goes on `jn-<data-slot>-<part>` instead
     (`jn-input-otp-container`), the class to give that element. Calendar's `classNames` parts
     have no slot at all: their utilities go in `calendar-parts.css`, on react-day-picker's own
     `rdp-<part>` classes, which Joinery's Calendar renders where DayPicker does.

   - transformStyle keeps five semantic classes on the element for its other transforms
     (`cn-rtl-flip`, `cn-font-heading`…), and other parts share them, so a rule never has one as
     its subject on its own. An element whose only semantic classes are kept ones (a
     sub-trigger's chevron, `cn-rtl-flip ml-auto`) gets its rule inside the nearest enclosing
     element with a class of its own (`:where(.jn-dropdown-menu-sub-trigger) > :where(.jn-rtl-flip)`),
     so it moves no Breadcrumb separator or Pagination arrow.

   The output also lists the `group/*` markers the element must keep, and leaves conditional
   classes as comments.

   The script reads one file, so where a part renders another upstream component
   (ItemSeparator and ButtonGroupSeparator render Separator), that component's inline
   utilities go after the output by hand, under a comment that says so. They come first in its
   `cn()` call, so the part's own classes beat them: leave out each one the part's rule or
   inline utilities override in any style (ButtonGroupSeparator's `bg-input` beats Separator's
   `bg-border`), since after the sheet it would win instead. Its ARIA comes from that
   component's primitive (the parts spread `separatorAria()` from
   `@ember-joinery/primitives/separator`), but the part doesn't render the styled component:
   component CSS goes in A–Z, so `separator.css`, after `item.css`, would beat the part's rules.

A component is done when it has everything listed under "Definition of done for every
component" in the plan: its primitive, the styled component, its harness, tests written with the
harness (including the keyboard pattern, controlled and uncontrolled state, RTL and an axe audit),
a guide page with every upstream example, a parity mapping for each example, and a changeset.

### The pattern, with Button as the reference

Button was ported first so every later component can copy it. A component `<name>` is these
files, each its own, so components land side by side without touching each other's:

| File                                                    | What it holds                                 |
| ------------------------------------------------------- | --------------------------------------------- |
| `packages/ember/src/components/<name>.gts`              | The component (the barrel exports it)         |
| `packages/ember/src/components/<name>.css`              | `extract-classes.mjs`'s output, kept whole    |
| `packages/test-support/src/<name>.ts`                   | Its harness, `<Name>Harness`                  |
| `test-app/tests/integration/components/<name>-test.gts` | Its tests, written with the harness           |
| `docs-app/app/templates/components/<name>.md`           | Its guide page                                |
| `docs-app/app/examples/<example>.gts`                   | One per upstream example, named as upstream's |
| `docs-app/tests/examples/<example>-test.gts`            | Each example's test                           |
| `parity/map/<name>.json`                                | Each upstream example, mapped                 |
| `.changeset/<name>.md`                                  | Its changeset                                 |

**The markup.** Each part renders what upstream's does, plus Joinery's test attributes:

- the classes upstream's source gives it: its semantic classes renamed (`jn-button
jn-button-variant-outline jn-button-size-sm`) and the markers `extract-classes.mjs` lists
  (`group/button`). A part upstream gives no semantic class gets `jn-<data-slot>`, the class
  the script's rules use (`jn-spinner`). An icon upstream sizes with a class (Spinner's
  `size-4`) keeps the marker the script names for it (`jn-size-4`): no rule styles it, but the
  style sheets' `svg:not([class*='size-'])` rules look for a `size-` class to leave an icon
  with its own size alone, as they do upstream's;
- `data-slot`, and Radix's `data-state` (`open`, `checked`…), as upstream's;
- typed `@variant` and `@size` arguments, rendered as `data-variant` and `data-size`, with
  upstream's defaults;
- `data-test-jn="<name>"` and `data-test-jn-name={{@name}}` on the root, and
  `data-test-jn-part` on each other part.

Render them in the template (so a server-rendered page is styled), with `...attributes` last,
so a caller's `class` adds to the component's and their attributes win.

**A part that floats.** A part placed against its trigger (a popover, a tooltip, a menu, a
select's list) takes Radix's Popper arguments with Radix's defaults, through
`packages/primitives/src/-private/popper.gts` (imported by relative path), as Popover, Tooltip
and Hover Card do: `popperOptions()` and `anchorContent` anchor it, `exposeProperties()` sets
the `--radix-<name>-content-transform-origin` (and the rest) that upstream's classes read,
`PopperArrow` is Radix's arrow, `Delay` is an open or close delay that `settled()` waits for,
and `graceArea()` is the path a pointer may cross to the content. In the top layer the content
is a popover, whose `overflow: auto` would clip an arrow: `src/css/base.css` resets the
browser's popover styles on every part (`[data-slot][popover]`), that one included, so test the
computed `overflow` rather than adding a rule. Two template traps: where a file imports
ember-modifier's `modifier`, `(modifier …)` in its templates means that function, not the
keyword (import it as `functionModifier`); and a curried `(modifier …)` is a new modifier
whenever its arguments change, so give one that keeps state (a focus scope) an `enabled`
argument rather than currying it in an `(if …)`. A part whose size follows its trigger's (a
select's list, `min-w-(--radix-select-trigger-width)`) calls `ignoreROError()` from
`resize-observer.ts`: anchoring sets that width from a resize observer, and the browser's benign
"ResizeObserver loop" message would otherwise fail the test.

**Your own element.** Every part takes `@as`, a tag (`<Button @as="a" href="/login">`), through
`As`. For a component of the caller's own, such as `LinkTo`, there is a part modifier made with
`part()`: a compound component yields one per part (`<LinkTo {{d.trigger}}>`), and a component
that is one part exports one, named `as<Name>` (`<LinkTo {{asButton variant="outline"}}>`).
Never name it after the component in lower case: a binding named `button` (or `input`, `label`,
`table`…) turns every `<button>` in the importing file's templates into a call to it. The
modifier and the template take their classes and attributes from the same functions
(`buttonClasses`, `buttonAttributes`), so both render the same thing, and a test checks it.

**Parts.** A compound component yields its parts in one object, each as a component and as its
modifier: Card yields `Header`, `Title`… and `header`, `title`… (`<c.Title @as="h3">`,
`<LinkTo {{c.title}}>`). A part with nothing of its own to track, which always renders the same
classes, `data-slot` and `data-test-jn-part`, comes from `staticPart()` and
`staticPartModifier()` in `packages/ember/src/-private/static-part.gts`, both made from the
one spec, as Alert's, Card's and Empty's are; a part that takes arguments, such as Empty's
`Media` (`@variant`), has its own template and `part()`, from shared functions as Button's.

**Icons and strings.** Upstream's `lucide-react` icons are `lucide`'s, drawn by `<Icon>`
(`ArrowUpIcon` is `<Icon @icon={{ArrowUp}} />`). An icon a component draws itself can be
replaced, and every string it shows is an argument with upstream's English as the default
(Spinner's `@label`, `Loading`). An icon upstream marks `cn-rtl-flip` (a breadcrumb's chevron,
pagination's arrows) keeps `jn-rtl-flip`, which `src/css/base.css` mirrors right to left, as
upstream's right-to-left build does.

**Parts with a tag of their own.** A part with nothing of its own to track whose element isn't
a `div` (a table's `tr`, a breadcrumb's `ol`) comes from `taggedPart()` and
`taggedPartModifier()` in `packages/ember/src/-private/tagged-part.gts`, both made from one spec
of its tag, classes, `data-slot`, `data-test-jn-part` and any ARIA upstream gives it, as
Table's, Breadcrumb's and Pagination's are.

**Controls in a form.** A control that is a button, as Radix's Checkbox, Switch and radios are,
takes part in a native form as Radix's does, through a hidden native input beside it (Radix's
"bubble input"): `FormControl` and `BubbleInput` in
`packages/primitives/src/-private/form-control.ts` (imported by relative path) find the
control's form once it has rendered, repeat its `name`, `value` and `form` attributes on the
input, keep the input checked with it, and fire `input` and `change` at the form. As on a native
input, the form field's name is the `name` attribute and `@name` stays the harness's; where the
root can't take a `name` (a radio group's `<div>`), it is an argument, `@formName`. In a test of
one, call the form element anything but `form`: a local by that name turns the template's
`<form>` into a call to it.

**The harness** extends `Harness`, names `static component`, reads state through the DOM and
ARIA (`label`, `isDisabled`, `isPressed`), and acts with `@ember/test-helpers` (`click()`,
`focus()`). The guide page's Testing section lists its members.

**The tests** cover rendering (classes and data attributes), every variant and size, the style
sheet actually styling it (computed sizes, so a missing rule fails), attributes and listeners,
controlled and uncontrolled state where it has any, the APG keyboard pattern and focus, `@as`
and the modifier, RTL (in a `DirectionProvider`, checking that logical sides flip), and the
harness's own members. Every test ends in `a11yAudit()`.

**Upstream's colours and AA.** Where upstream's own colours fall short of WCAG AA's 4.5:1 for
small text in its light themes (Kbd's keys, `--muted-foreground` on `--muted`; the destructive
Badge, `--destructive` on its own tint), Joinery keeps them: the component's page says so in its
Accessibility notes, with the CSS that meets AA, and the audits leave out only those elements
(`a11yAudit({ include: [['#ember-testing-container']], exclude: [[selector]] })` in a test that
needs it, and a file in `docs-app/tests/acceptance/upstream-contrast/` for the guide's pages
test), so everything around them is still checked. Better still, leave them out of the
colour-contrast rule alone, as Avatar's tests and the pages test do: one audit with
`color-contrast` turned off, then one that runs only it (`runOnly: ['color-contrast']`) with
those elements excluded, so every other rule still runs on them.

**The guide page** follows its ui.shadcn.com page: the title and description, the first example,
Installation, Usage, then each of upstream's sections in upstream's order, with its `<Example>`
and upstream's text (in Joinery's terms: `@variant` for `variant`), then API Reference
(arguments, the modifier, data attributes), Keyboard interactions, Accessibility, Testing and
Upstream (the link and the pinned commit).

**The examples** are upstream's, line for line: the same text, the same layout classes (the
guide compiles Tailwind's utilities for them, see "The guide") and the same icons. Where one has
to differ, a comment in it says why: an icon-only button upstream leaves unnamed gets
`aria-label`, so the audit passes, and an icon from another set is lucide's. An example that
needs a component that hasn't landed waits for it, and the gap is listed in the PR.

**Waiting examples.** A waiting example keeps its section on the page, with upstream's text
and a line saying what it comes with, and stays out of the parity map (so
`--require-complete` still counts it). The page's map names it, and what it waits for, in its
`$comment`. When you land a component, look for its name there (`grep -l 'Badge'
parity/map/*.json`), port the examples that waited for it onto their pages, map them, and take
them out of the `$comment`. So Button's page waits for Dropdown Menu: its `button-group-demo` (mapped
on Button Group's page) goes back in Button's Button Group section, which links to Button Group's
page.

**The parity map** lists every example on the page. One shown on two pages
(`button-group-demo` is on Button's and Button Group's) is mapped on the page the inventory
names as its `page`.

## Tests first

Behaviour changes start with a failing test in `test-app/tests/`. Write tests with harness
classes, not raw selectors. A new component gets a harness class; page objects are harness
subclasses with `@child` declarations. Every test ends in an axe audit.

A part that opens on hover (a tooltip, a hover card) is tested with `hover()` and `unhover()`
from `@ember-joinery/test-support`, which move the pointer as a mouse does (`click()` sends no
pointer events); its delays hold `settled()`, so a test waits them out.

A component's harness extends `Harness` from `@ember-joinery/test-support`: it names its
`data-test-jn` value in `static component`, reaches its parts with `part()`, and reads state
through ARIA. The package's README covers the base class and the `data-test-jn-*` selector
reference, and `test-app/tests/fixtures/harness/` has small examples. A component that wraps
the caller's content (a `Scroller`, a layout, a `Heading`) marks its root
`data-test-jn-wrapper`, so the parts inside stay the component's around it, and styles its own
elements by `data-jn-*` attributes rather than `data-slot`, because joinery.css resets every
`[data-slot]` and all it holds.

## Parity

`pnpm parity` renders each mapped upstream example in the React reference app (`parity/`) and
the matching Ember example in the guide's `/parity/<name>` route, then compares screenshots in
light and dark: the same fixed viewport, fonts and Chromium on both sides, with animations off.
Each page's images have loaded (or failed) first, both those in the page and those an avatar
loads off it (`new Image()`, as Radix's and Joinery's do) before it swaps out its fallback, so
both sides show the same state. The diff is measured over the content's bounding box, the smallest box holding everything on
either page that isn't the background (the whole page, if the two backgrounds differ), so an
empty stage or a missing part fails however small the example is. Two pixels count as different
when they are more than about 8 levels of grey apart, so a 1px `--border` line or a `--muted`
fill registers; pixelmatch still leaves anti-aliased edges out. A diff over the threshold (1% of
the box's pixels) fails, unless the map gives that example its own threshold (one for both
themes, or one for each) along with a written reason, or compares only a `region` of it (a
CSS selector, such as the chart inside a charts gallery card). Both pages showing nothing but
the background is an error. The report, with the compared areas and their diff side by side, is
written to `parity-report/index.html` (CI uploads it from `parity.yml`).

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
  page needs no list edited. A page's examples may repeat a landmark, as upstream's do (every
  Breadcrumb is a nav called `breadcrumb`), so its `landmark-unique` check covers the guide's
  own landmarks and leaves the previews out; each example's own test audits it alone. A block
  preview (`@block={{true}}`) renders in a frame of its own, which axe doesn't enter from the
  page, so the pages test checks that it rendered and audits only the frame around it: its
  example's own test is what audits the block. Where a
  component keeps upstream's colours though they fall short of WCAG AA's contrast (see
  "Upstream's colours and AA"), it lists those elements, with the reason, in its own
  `docs-app/tests/acceptance/upstream-contrast/<component>.ts`: the pages test leaves them out
  of the colour-contrast rule only, and runs every other rule on them.
- Examples are `.gts` files in `docs-app/app/examples/`, one per upstream example, named
  `<component>-<example>`, each exporting the example as its default export. Show one in a page
  with `<Example @name="…" />` (add `@title`, `@align="start"` where upstream's preview aligns
  it, and `@fullWidth={{true}}` where upstream shows it full width: the chart demo's
  `[&_.preview>div]:w-full`, the charts gallery's interactive and tooltip charts; map those with
  `"fullWidth": true` too, so both parity stages widen them; `@block={{true}}` for a whole
  screen, which upstream previews as `type="block"` in an `<iframe>`, as the sidebar's: the
  preview renders in a frame 600px tall, so its fixed parts, `svh` heights and breakpoints are
  the frame's, and a component that measures its window (the Sidebar) measures the frame's).
  Where upstream's
  `<ComponentPreview>` sizes its preview (`previewClassName`) or lets it overflow its frame
  (`className="overflow-visible"`), as `upstream/inventory.json` records, pass the same:
  `@previewClass="h-96"` puts upstream's classes on the preview (add each class to
  `@source inline()` in `docs-app/app/styles/examples.css`, which compiles them), and
  `@overflow="visible"` stops the frame clipping a part that hangs below the example outside the
  top layer, as a navigation menu's viewport does. `docs-app/tests/unit/preview-classes-test.ts`
  checks both against the inventory; the parity stages leave them out. The frame has Preview, Template
  and Test tabs and a copy button. Above the preview, switchers show it in any of the eight
  styles, base colours and radii, light or dark, right to left, and in a 375, 768 or 1440px
  viewport (an `<iframe>` that wide, so the breakpoints respond). The guide loads every style,
  each scoped to the previews that pick it (`docs-app/joinery-css.mjs` builds that from the
  package's `dist/`, and what an app's sheet sets on `:root`, the radius scale, it sets on the
  preview), and the base colour and radius are tokens on the preview itself. A preview, like
  the parity route's stage, is rendered anew when its style changes: a browser doesn't restyle
  what's inside an `@scope` root when its `data-style` changes in place.
- An example lays itself out with upstream's Tailwind classes. `docs-app/app/styles/examples.css`
  compiles Tailwind's utilities from `docs-app/app/examples` only, with no preflight, into
  `@layer utilities` above Joinery's, so a class on a component overrides its style as on
  ui.shadcn.com. Typography's examples are the one exception: bare headings, paragraphs,
  lists and tables styled with nothing but utilities, which rely on preflight, as any Tailwind
  app gives it. examples.css gives those examples alone the share of preflight
  they need, keyed on the stage's `data-example` (the frame's) or `data-parity` (the parity
  route's), so every other example still shows Joinery as an app without Tailwind sees it.
- Upstream's right-to-left examples (`<name>-rtl`, whose `<ComponentPreview>` has
  `direction="rtl"`) are shown with `<Example @name="<name>-rtl" @dir="rtl" />`. `@dir` puts
  `dir` on the preview, as the parity route's `?dir=rtl` does, and Joinery's components take
  their direction from the nearest `dir`, so the example needs no provider of its own. Port
  the Arabic text: upstream's preview opens in Arabic (it also offers Hebrew and English, a
  picker the frame doesn't have).
- Every example has a test, `docs-app/tests/examples/<name>-test.gts`, written with harness
  classes and ending in an axe audit. A test renders its example in Nova, as a preview starts
  (the test helper puts `data-style="nova"` on the test's root). The guide shows it in the example's Test tab, so write it
  the way you'd want a reader to write theirs. `docs-app/tests/unit/examples-test.ts` fails
  when an example has no test, a test has no example, or a test never calls `a11yAudit()`.
- The guide's own CSS (`docs-app/app/styles/app.css`) sits in `@layer guide`, below
  `@layer joinery`, so Joinery's rules win wherever a component renders. The example's preview
  and the parity route are a `guide-stage`, and the guide's rules stop there: its prose and
  link rules are `@scope`d to stop at an example, its `box-sizing: border-box` reset covers the
  stage but not what's inside, and the text styles the page would pass down (font, size, line
  height, colour) start over, as in upstream's preview, with `--font-sans` and `--font-mono` set
  to Geist's, as ui.shadcn.com sets them, for a part that sets its own font (Kbd's keys). The
  stage adds no reset of its own, so the guide and the parity comparison see Joinery as an app
  without Tailwind does. That
  includes box sizing: upstream's parts get `border-box` from Tailwind's preflight, and
  joinery.css gives Joinery's parts the same (`src/css/base.css`, scoped to `[data-slot]`), so
  the parity comparison catches a part that misses it. Keep new guide rules inside the layer, and scope any that select bare elements or
  every element.
- `/parity/<name>` renders one example with no frame and no guide around it, centred as
  upstream's preview is, for the screenshot comparison. `?theme=dark` puts `.dark` on `<html>`
  and `?theme=light` (the default) puts `.light` there; either also pins `color-scheme`, so the
  browser's or OS's preference can't change the page. `?dir=rtl` lays it out right to left,
  `?align=start|end` places it, `?fullWidth=true` stretches it across the stage, and `?style=`
  and `?base=` pick a style and a base colour (Nova and Neutral by default). The example's root
  carries `data-parity="<name>"`; an unknown name renders `data-parity-missing` instead.

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

Each app imports `tokens.css` and `joinery.css`, and the Tailwind one `tailwind.css` too, and
renders a Button with a lucide icon, which its smoke test drives with `ButtonHarness`: that is
what proves a classic app consumes `.gts` v2 addon components. The Vite and classic apps also
render six add-ons: a Code Block, highlighted, which proves an add-on and the Shiki it loads on
demand build in both, a Carousel, which their smoke tests move with `CarouselHarness`, so an
add-on with a dependency of its own (Embla) builds both ways too, a File Upload, which they
fill with `FileUploadHarness`, so an add-on on another v2 addon (ember-file-upload, with its
macros) does too, a data table, which they sort with `DataTableHarness` (TanStack Table's
core reads `process.env.NODE_ENV`, which both builds replace), a Rich Text Editor, which they
format with `RichTextEditorHarness`, so an add-on on Tiptap and ProseMirror does too, and a
DatePicker, which they open and choose a day in with `DatePickerHarness`, so an add-on on a v2
addon whose app tree carries a service (ember-power-calendar) does too.
