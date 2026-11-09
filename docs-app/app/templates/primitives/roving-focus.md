# Roving Focus

A group of items that takes one stop in the tab order, with the arrow keys moving between them:
WAI-ARIA's [roving tabindex](https://www.w3.org/WAI/ARIA/apg/practices/keyboard-interface/#kbd_roving_tabindex),
as toolbars, tab lists, radio groups, toggle groups and menus use it. It is Radix's
`RovingFocusGroup`, and the arrow-key movement that ember-primitives gets from tabster's Mover.

<Example @name="roving-focus-toolbar" @title="A toolbar" />

## Usage

```gts
import { RovingFocusGroup } from '@ember-joinery/primitives/roving-focus'

<template>
  <RovingFocusGroup
    @orientation="horizontal"
    @loop={{true}}
    role="toolbar"
    aria-label="Formatting"
    as |group|
  >
    <group.Item @as="button" @tabStopId="bold" type="button">Bold</group.Item>
    <group.Item @as="button" @tabStopId="italic" type="button">Italic</group.Item>
    <button type="button" {{group.item tabStopId="link"}}>Link</button>
  </RovingFocusGroup>
</template>
```

- **One tab stop.** Tab enters the group on the `@active` item (a selected tab), else the item
  focused last, else the first; Tab again leaves it. Until an item has been focused, the group
  itself is in the tab order and passes focus on.
- **The arrow keys** move to the previous or next item: left and right with
  `@orientation="horizontal"`, up and down with `"vertical"`, all four when it is unset.
  **Home** and **PageUp** go to the first item, **End** and **PageDown** to the last. With
  `@loop`, the arrows go round from the last item to the first and back.
- **Right to left**, left and right swap, so the left arrow moves forward. The group reads the
  direction from the document (a `dir` around it), or from `@dir`.
- Items with `@focusable={{false}}` (a disabled tab) are passed over.
- **Shift+Tab** from an item leaves the group in one step, rather than landing on the group.

Each item is `group.Item` (a `<span>` by default, as in Radix, or `@as` any tag), or the
yielded `group.item` modifier on an element of your own. `group.Item` yields
`{ isCurrentTabStop, hasTabStop }`, and the group yields `currentTabStopId`.

### In a component

A component that has its own parts puts the group's two modifiers on them, beside its own:

```ts
import { RovingFocus } from '@ember-joinery/primitives/roving-focus'

class TabList extends Component {
  roving = new RovingFocus({
    orientation: () => this.args.orientation ?? 'horizontal',
    dir: () => this.args.dir,
    loop: () => this.args.loop ?? true,
  })

  isSelected = (tab: Tab) => tab.value === this.args.value
  isEnabled = (tab: Tab) => !tab.disabled
}
```

```gts
<div role="tablist" {{this.roving.group}}>
  {{#each @tabs as |tab|}}
    <button
      type="button"
      role="tab"
      {{this.roving.item
        tabStopId=tab.value
        active=(this.isSelected tab)
        focusable=(this.isEnabled tab)
      }}
    >{{tab.label}}</button>
  {{/each}}
</div>
```

`getFocusIntent(event, orientation, dir)` reads a key press the same way
(`'first' | 'last' | 'prev' | 'next'`), for a component that moves something other than focus.

## API

`RovingFocusGroup`:

| Argument                     | Type                           | Default        | What it does                                                         |
| ---------------------------- | ------------------------------ | -------------- | -------------------------------------------------------------------- |
| `@orientation`               | `'horizontal' \| 'vertical'`   | both           | Which arrow keys move focus                                          |
| `@dir`                       | `'ltr' \| 'rtl'`               | the document's | Which way left and right go                                          |
| `@loop`                      | `boolean`                      | `false`        | Go round from the last item to the first                             |
| `@currentTabStopId`          | `string \| null`               |                | The tab stop, controlled                                             |
| `@defaultCurrentTabStopId`   | `string`                       |                | The first tab stop, uncontrolled                                     |
| `@onCurrentTabStopIdChange`  | `(id: string \| null) => void` |                | Called with each new tab stop                                        |
| `@onEntryFocus`              | `(event: Event) => void`       |                | Before Tab passes focus on; `preventDefault()` keeps it on the group |
| `@preventScrollOnEntryFocus` | `boolean`                      | `false`        | Don't scroll that item into view                                     |
| `@as`                        | tag name                       | `div`          | The tag to render                                                    |
| `@name`                      | `string`                       |                | The harness's name for it                                            |

`group.Item` and `{{group.item}}`:

| Argument     | Type      | Default    | What it does                                    |
| ------------ | --------- | ---------- | ----------------------------------------------- |
| `@tabStopId` | `string`  | its own id | The item's id, for the tab stop and the harness |
| `@focusable` | `boolean` | `true`     | Whether focus can land on it                    |
| `@active`    | `boolean` | `false`    | Tab enters on it first                          |
| `@as`        | tag name  | `span`     | The tag to render (`group.Item` only)           |

The group and its items have `data-orientation`, and take attributes. The group has
`data-slot="roving-focus-group"`.

## Keyboard interactions

| Key                    | What it does                                      |
| ---------------------- | ------------------------------------------------- |
| Tab                    | Into the group, on its tab stop; again, out of it |
| Shift+Tab              | Out of the group, backwards                       |
| ArrowRight / ArrowDown | The next item (ArrowLeft is next, right to left)  |
| ArrowLeft / ArrowUp    | The previous item                                 |
| Home / PageUp          | The first item                                    |
| End / PageDown         | The last item                                     |

## Testing

```ts
import { RovingFocusGroupHarness, tab } from '@ember-joinery/test-support'

const toolbar = new RovingFocusGroupHarness('formatting') // @name="formatting"
await tab() // into the group
toolbar.focused // 'bold': the focused item's id
await toolbar.press('ArrowRight')
toolbar.tabStop // 'italic': where Tab comes back to
toolbar.ids // every item's id, in order
toolbar.item('italic') // one item's element
await toolbar.focus('italic')
```

| Member            | What it is                                                   |
| ----------------- | ------------------------------------------------------------ |
| `items`, `ids`    | The items' elements and ids, in order                        |
| `item(id)`        | One item's element                                           |
| `focused`         | The id of the focused item, or `null`                        |
| `tabStop`         | The id of the item with `tabindex="0"`, or `null`            |
| `isGroupTabbable` | Whether Tab stops on the group itself, on its way to an item |
| `orientation`     | `horizontal`, `vertical`, or `undefined`                     |
| `focus(id)`       | Focuses an item                                              |
| `press(key)`      | Presses a key on the focused item                            |
