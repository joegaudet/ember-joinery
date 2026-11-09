# Tabs

A set of layered sections of content, known as tab panels, that are displayed one at a time.
It is Radix's `Tabs`, and covers ember-primitives' too: link tabs, the activation mode, and the
first tab selected when no value is given. It has no styles; the styled
[Tabs](/components/tabs.md) is built on it.

<Example @name="tabs-headless" @title="Package managers" />

## Usage

```gts
import { Tabs } from '@ember-joinery/primitives/tabs'

<template>
  <Tabs @defaultValue="npm" @activationMode="manual" as |t|>
    <t.List aria-label="Install with your package manager">
      <t.Trigger @value="npm">npm</t.Trigger>
      <t.Trigger @value="pnpm">pnpm</t.Trigger>
    </t.List>
    <t.Content @value="npm">npm add @ember-joinery/primitives</t.Content>
    <t.Content @value="pnpm">pnpm add @ember-joinery/primitives</t.Content>
  </Tabs>
</template>
```

- **The value.** `@defaultValue` starts it, or `@value` and `@onValueChange` own it;
  `@onValueChange(value, previous)` also hears the value before, as ember-primitives'
  `@onChange` does. With neither, the first tab that isn't disabled is selected, as in
  ember-primitives; `@defaultValue=""`, or a `@value` no tab has, selects none, as in Radix.
- **Focus.** The tabs share one tab stop, on the [roving focus](/primitives/roving-focus.md):
  Tab enters on the selected tab, the arrows along `@orientation` move between tabs and wrap
  round (`@loop={{false}}` on the list stops them at the ends), and Home and End go to the
  ends. Right to left (`@dir`, or the nearest `dir`), left and right swap.
- **Activation.** `@activationMode="automatic"` (the default) selects a tab as it takes focus;
  `"manual"` waits for Enter, Space or a click.
- **Panels.** A panel's block renders only while its tab is selected (or with `@forceMount`).
  The panel stays, `hidden`, and a tab names its panel in `aria-controls` once it is there, so
  tabs work with no panels at all, as upstream's examples show them.
- Each part is a component (`t.List`, `t.Trigger`, `t.Content`, each with `@as`), or a modifier
  on an element of your own (`t.list`, `t.trigger`, `t.content`).

### Link tabs

A tab on a link (`<a href>`, or a `LinkTo`) is a link tab, ember-primitives' `Label.Link`: a
click selects it as it navigates, but focus never does, whatever the activation mode, because
focus doesn't navigate. Take the selection from the route, so the back button and deep links
keep it, and put the routed page in one panel with the selected value:

```gts
import Component from '@glimmer/component'
import { LinkTo } from '@ember/routing'
import { service } from '@ember/service'
import { Tabs } from '@ember-joinery/primitives/tabs'

export default class SettingsNav extends Component {
  @service router

  <template>
    <Tabs @value={{this.router.currentRouteName}} as |t|>
      <t.List aria-label="Settings">
        <LinkTo @route="profile" {{t.trigger value="profile"}}>Profile</LinkTo>
        <LinkTo @route="billing" {{t.trigger value="billing"}}>Billing</LinkTo>
      </t.List>
      <t.Content @value={{t.value}}>{{yield}}</t.Content>
    </Tabs>
  </template>
}
```

A disabled link tab gets `aria-disabled="true"`, and its clicks are stopped.

### From ember-primitives

ember-primitives' `<Tabs @label as |Tab|><Tab @label @content />` puts a tab and its panel in
one `Tab`; here they are `t.Trigger` and `t.Content`, as in Radix. Its `@activeTab` and
`@onChange` are `@value` and `@onValueChange`, and its `@label` (or `Tab.Label`) is the list's
`aria-label` (or `aria-labelledby`). Tabs nest: each set keeps its own tabs, panels and arrow
keys.

### In a component

`TabsState` is the tabs' behaviour, for a component that renders its own parts, as the styled
one does. Its `listModifier()`, `triggerModifier()` and `contentModifier()` take a function
that adds to each part's spec, so a component can put its own classes on them:

```ts
import { TabsState } from '@ember-joinery/primitives/tabs'

class SettingsTabs extends Component {
  tabs = new TabsState({ defaultValue: () => 'account' })
  trigger = this.tabs.triggerModifier(spec => ({ ...spec, class: 'my-tab' }))
}
```

```gts
<div {{this.tabs.list}}>
  <button type="button" {{this.trigger value="account"}}>Account</button>
</div>
<div {{this.tabs.content value="account"}}>…</div>
```

## API

| Argument          | Type                                        | Default        | What it does                                      |
| ----------------- | ------------------------------------------- | -------------- | ------------------------------------------------- |
| `@defaultValue`   | `string`                                    | the first tab  | The tab selected first, uncontrolled              |
| `@value`          | `string`                                    |                | The selected tab, controlled                      |
| `@onValueChange`  | `(value: string, previous: string) => void` |                | Called with each new value, and the one before    |
| `@orientation`    | `"horizontal" \| "vertical"`                | `"horizontal"` | Which arrows move between tabs                    |
| `@activationMode` | `"automatic" \| "manual"`                   | `"automatic"`  | Whether focus selects a tab, or only a press      |
| `@dir`            | `"ltr" \| "rtl"`                            | the document's | The text direction                                |
| `@as`             | tag name                                    | `div`          | The tag to render                                 |
| `@name`           | `string`                                    |                | Its name, for `TabsHarness` (`data-test-jn-name`) |

It yields `t.List` (`@loop`, `@as`), `t.Trigger` (`@value`, `@disabled`, `@as`), `t.Content`
(`@value`, `@forceMount`, `@as`), the modifiers `t.list`, `t.trigger` and `t.content`, which take
the same, `t.value`, `t.isSelected(value)` and `t.select(value)`.

| Part      | Attributes                                                                                                                 |
| --------- | -------------------------------------------------------------------------------------------------------------------------- |
| Root      | `data-orientation`, `dir` (with `@dir`)                                                                                    |
| t.List    | `role="tablist"`, `aria-orientation`, `data-orientation`, and the roving `tabindex`                                        |
| t.Trigger | `role="tab"`, `aria-selected`, `aria-controls`, `data-state` (`active` or `inactive`), `data-disabled`, `data-orientation` |
| t.Content | `role="tabpanel"`, `aria-labelledby`, `tabindex="0"`, `data-state`, `data-orientation`, `hidden` while inactive            |

## Testing

```ts
import { TabsHarness } from '@ember-joinery/test-support'

const install = new TabsHarness()
await install.focus('npm')
await install.press('ArrowRight')
await install.press('Enter')
assert.strictEqual(install.selected, 'pnpm')
```

See the styled [Tabs](/components/tabs.md#testing) for every member.
