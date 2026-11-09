# Tabs

A set of layered sections of content—known as tab panels—that are displayed one at a time.

Upstream's first example puts each panel in a Card, which hasn't landed in Joinery yet; it
comes with Card. Until then, this is upstream's Usage snippet, live:

<Example @name="tabs-usage" @title="Tabs" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Tabs } from '@ember-joinery/ember'
```

## Usage

```gts
<Tabs @defaultValue="account" class="w-[400px]" as |t|>
  <t.List>
    <t.Trigger @value="account">Account</t.Trigger>
    <t.Trigger @value="password">Password</t.Trigger>
  </t.List>
  <t.Content @value="account">Make changes to your account here.</t.Content>
  <t.Content @value="password">Change your password here.</t.Content>
</Tabs>
```

Start it on a tab with `@defaultValue`, or own the selection with `@value` and
`@onValueChange`, which hears each new value and the one before it. With neither, the first tab
that isn't disabled is selected, as in ember-primitives (Radix selects none; pass
`@defaultValue=""` for that).

Joinery's tabs select a tab as soon as it takes focus (`@activationMode="automatic"`, as
Radix's), so the arrow keys show each panel in turn. With `@activationMode="manual"`, the arrows
only move focus, and Enter, Space or a click selects; use it when a panel is slow to show. The
headless [Tabs](/primitives/tabs.md) primitive's example is manual.

## Composition

Use the following composition to build `Tabs`:

```text
Tabs
├── t.List
│   ├── t.Trigger
│   └── t.Trigger
├── t.Content
└── t.Content
```

`Tabs` yields its parts as `t.List`, `t.Trigger` and `t.Content`, and as the modifiers `t.list`,
`t.trigger` and `t.content` for elements and components of your own, which render the same:

```gts
<Tabs @value={{this.router.currentRouteName}} as |t|>
  <t.List>
    <LinkTo @route="account" {{t.trigger value="account"}}>Account</LinkTo>
    <LinkTo @route="password" {{t.trigger value="password"}}>Password</LinkTo>
  </t.List>
  <t.Content @value={{t.value}}>{{outlet}}</t.Content>
</Tabs>
```

A tab that is a link (`<a href>`, or a `LinkTo`) is a link tab: it navigates, so focus never
selects it, whatever `@activationMode` says, and the selection comes from the route, through
`@value`. One panel around the `{{outlet}}`, with the selected value, holds the routed page.

## Line

Use the `@variant="line"` argument on `t.List` for a line style.

<Example @name="tabs-line" @title="Line" />

## Vertical

Use `@orientation="vertical"` for vertical tabs.

<Example @name="tabs-vertical" @title="Vertical" />

The arrow keys follow the orientation: up and down move between vertical tabs, left and right
between horizontal ones.

## Disabled

<Example @name="tabs-disabled" @title="Disabled" />

Disable a tab with `@disabled={{true}}` (not the `disabled` attribute), so it is marked
`data-disabled` and the arrow keys pass it by.

## Icons

<Example @name="tabs-icons" @title="Icons" />

## RTL

To enable RTL support, see the [Direction](/primitives/direction.md) guide. The tabs take their
direction from the nearest `dir`, or from `@dir`: right to left, they run from the right, the
left arrow moves forward, and a vertical line tab's line moves to the left side. Upstream's
example (`tabs-rtl`) puts each panel in a Card; it comes with Card.

## API Reference

### Tabs

| Argument          | Type                                        | Default        | What it does                                                   |
| ----------------- | ------------------------------------------- | -------------- | -------------------------------------------------------------- |
| `@defaultValue`   | `string`                                    | the first tab  | The tab selected first, uncontrolled                           |
| `@value`          | `string`                                    |                | The selected tab, controlled                                   |
| `@onValueChange`  | `(value: string, previous: string) => void` |                | Called with each new value, and the one before (`''` for none) |
| `@orientation`    | `"horizontal" \| "vertical"`                | `"horizontal"` | Which way the tabs run, and which arrows move between them     |
| `@activationMode` | `"automatic" \| "manual"`                   | `"automatic"`  | Whether focus selects a tab, or only a press does              |
| `@dir`            | `"ltr" \| "rtl"`                            | the document's | The text direction                                             |
| `@as`             | tag name                                    | `div`          | The tag to render                                              |
| `@name`           | `string`                                    |                | Its name, for `TabsHarness` (`data-test-jn-name`)              |

It yields `t.List`, `t.Trigger`, `t.Content`, the modifiers `t.list`, `t.trigger` and
`t.content`, `t.value` (the selected value), `t.isSelected(value)` and `t.select(value)`.

### t.List

| Argument   | Type                  | Default     | What it does                                    |
| ---------- | --------------------- | ----------- | ----------------------------------------------- |
| `@variant` | `"default" \| "line"` | `"default"` | A muted bar, or a line under the selected tab   |
| `@loop`    | `boolean`             | `true`      | Whether the arrows wrap round from end to start |
| `@as`      | tag name              | `div`       | The tag to render                               |

`{{t.list variant=… loop=…}}` is the same on your own element; `tabsListClasses()` and
`tabsListAttributes()` return its look, as upstream's `tabsListVariants` does.

### t.Trigger

| Argument    | Type      | Default  | What it does                                             |
| ----------- | --------- | -------- | -------------------------------------------------------- |
| `@value`    | `string`  |          | The value it selects, unique among the tabs              |
| `@disabled` | `boolean` | `false`  | Whether it can't be selected; focus passes it by         |
| `@as`       | tag name  | `button` | The tag to render; `a`, with `href`, makes it a link tab |

`{{t.trigger value=… disabled=…}}` is the same on your own element or component. On a
`<button>` of your own it sets `type="button"`, unless the button has a type.

### t.Content

| Argument      | Type      | Default | What it does                                                           |
| ------------- | --------- | ------- | ---------------------------------------------------------------------- |
| `@value`      | `string`  |         | The value of the tab that shows it                                     |
| `@forceMount` | `boolean` | `false` | Keep it rendered and shown while inactive, for CSS of your own to hide |
| `@as`         | tag name  | `div`   | The tag to render                                                      |

Its block renders only while its tab is selected. The panel itself stays, `hidden`.
`{{t.content value=… forceMount=…}}` is the same on your own element, whose content always
renders (`hidden` hides it).

### Data attributes

| Part      | `class`                                                       | Data attributes                                                                                        |
| --------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| Tabs      | `jn-tabs group/tabs`                                          | `data-slot="tabs"`, `data-orientation`                                                                 |
| t.List    | `jn-tabs-list group/tabs-list jn-tabs-list-variant-<variant>` | `data-slot="tabs-list"`, `data-variant`, `data-orientation`                                            |
| t.Trigger | `jn-tabs-trigger`                                             | `data-slot="tabs-trigger"`, `data-state` (`active` or `inactive`), `data-disabled`, `data-orientation` |
| t.Content | `jn-tabs-content`                                             | `data-slot="tabs-content"`, `data-state`, `data-orientation`                                           |

The root also has `data-test-jn="tabs"` and `data-test-jn-name`; the list
`data-test-jn-part="list"`; each tab `data-test-jn-part="trigger"` and each panel
`data-test-jn-part="content"`, both with `data-test-jn-value`, their `@value`.

## Keyboard interactions

| Key                       | What it does                                                       |
| ------------------------- | ------------------------------------------------------------------ |
| `Tab`                     | Moves focus to the selected tab; from there, into the panel and on |
| `Shift+Tab`               | From a tab, out of the list, backwards                             |
| `ArrowRight`, `ArrowLeft` | Moves to the next or previous tab, horizontally (and selects it)   |
| `ArrowDown`, `ArrowUp`    | Moves to the next or previous tab, vertically (and selects it)     |
| `Home`, `End`             | Moves to the first or last tab (and selects it)                    |
| `Enter`, `Space`          | Selects the focused tab, with `@activationMode="manual"`           |

That is the [APG tabs pattern](https://www.w3.org/WAI/ARIA/apg/patterns/tabs/). The tabs share
one tab stop (a [roving tabindex](/primitives/roving-focus.md)), the arrows wrap round unless
`@loop={{false}}`, and right to left, left and right swap. With automatic activation, moving to
a tab selects it; disabled tabs are passed by.

## Accessibility

- The list is a `role="tablist"` with `aria-orientation`; give it an `aria-label` when its
  purpose isn't clear from around it.
- Each tab is a `role="tab"` with `aria-selected`, and `aria-controls` naming its panel, once
  the panel is rendered (upstream's examples show tabs with no panels). Each panel is a
  `role="tabpanel"`, labelled by its tab, and in the tab order (`tabindex="0"`), so a panel
  with nothing to focus can still be reached. Give a panel `tabindex="-1"` of your own when its
  first element takes focus.
- A disabled tab is `disabled` (`aria-disabled` on a link tab).

## Testing

`TabsHarness` from `@ember-joinery/test-support` drives a `<Tabs>`:

```ts
import { TabsHarness } from '@ember-joinery/test-support'

const settings = new TabsHarness('settings') // <Tabs @name="settings">
await settings.select('password')
assert.strictEqual(settings.selected, 'password')
assert.strictEqual(settings.panelText, 'Change your password here.')
```

| Member                       | What it is                                                    |
| ---------------------------- | ------------------------------------------------------------- |
| `selected`                   | The selected tab's value (`aria-selected`), or `null`         |
| `isSelected(value)`          | Whether a tab is selected                                     |
| `panel`, `panelText`         | The panel shown now (its tab's `aria-controls`), and its text |
| `isShown(value)`             | Whether a panel is rendered and not `hidden`                  |
| `tabValues`                  | Every tab's value, in order                                   |
| `triggers`, `trigger(value)` | The tabs' elements                                            |
| `content(value)`, `list`     | A panel's element, and the list's                             |
| `isDisabled(value)`          | `disabled`, or `aria-disabled="true"` on a link               |
| `isLink(value)`              | Whether a tab is a link tab                                   |
| `label(value)`, `listLabel`  | A tab's name, and the list's                                  |
| `orientation`, `variant`     | The list's `aria-orientation`, and its `@variant`             |
| `tabStop`, `focused`         | The tab Tab lands on, and the one with focus                  |
| `select(value)`              | Clicks a tab; a disabled one ignores it                       |
| `focus(value)`, `press(key)` | Focuses a tab; presses a key where focus is                   |

## Upstream

shadcn/ui's [Tabs](https://ui.shadcn.com/docs/components/radix/tabs), from
`apps/v4/registry/bases/radix/ui/tabs.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
