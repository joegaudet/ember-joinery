# Command

The headless part under Joinery's [Command](/components/command.md): cmdk's command menu, with
no styles, which also covers ember-primitives' `CommandPalette`. A search box over a list that
it filters and ranks as you type, with a selection the keys move while focus stays in the box.

<Example @name="command-headless" @title="Searching the docs" />

## Usage

```gts
import { Command } from '@ember-joinery/primitives/command'

<template>
  <Command @label="Command Menu" @onSelect={{this.run}} as |c|>
    <c.Input placeholder="Type a command or search..." />
    <c.List>
      <c.Empty>No results found.</c.Empty>
      <c.Group @heading="Letters">
        <c.Item>a</c.Item>
        <c.Item>b</c.Item>
        <c.Separator />
        <c.Item>c</c.Item>
      </c.Group>
      <c.Item @keywords={{array "fruit"}}>Apple</c.Item>
    </c.List>
  </Command>
</template>
```

- **Filtering and ranking.** An item's value is its `@value`, or its text (trimmed, each run
  of spaces one space). Typing scores every item with `@filter`, cmdk's fuzzy match by
  default (`defaultFilter`, its command score: the typed characters in order, runs and word
  starts above skips), its `@keywords` counting as more of its text. Items that score 0 aren't
  rendered. The rest show best first: in each group, and the groups by their best item, with
  items outside a group ahead of the groups, as cmdk sorts them. `@shouldFilter={{false}}`
  turns it off, for items you filter yourself, as ember-primitives' palette leaves to you.
- **The order.** cmdk moves the elements; Glimmer owns these, so they keep their place in the
  DOM and show in order through CSS `order`, their container a column of flex items, with
  `aria-posinset` and `aria-setsize` saying where each is. When the search clears, they go
  back to their own order.
- **Groups, separators and Empty.** A group with nothing left stays rendered, `hidden`; the
  separators aren't rendered during a search (unless `@alwaysRender`); Empty is rendered only
  while nothing matches. `@forceMount` keeps an item or a group whatever the search.
- **The selection.** One item is selected (`aria-selected`, `data-selected`, and the input's
  `aria-activedescendant`): the first result, after each search, unless the keys or the pointer
  move it. Own it with `@value` and `@onValueChange`. Enter clicks it, so an item that is a
  link (`<c.Item @as="a" href="/docs">`) navigates as a click would, and a ⌘-click on one
  opens it elsewhere and leaves the command be.
- **The search.** Own the input's text with `@search` and `@onSearchChange` (ember-primitives'
  `@query` and `@onQueryChange`), or start it with `@defaultSearch`. The command yields
  `search` and `setSearch` for a "clear" button of your own.
- **The count.** A visually hidden `role="status"` says how many results there are as they
  change (`3 results`), as ember-primitives' palette does; `@resultsText` words it.
- **A hotkey.** `@hotkey="mod+k"` calls `@onOpen` from anywhere on the page, as
  ember-primitives' palette does. `mod` is ⌘ on a Mac and Ctrl elsewhere.

`<Command>` yields `Input`, `List`, `Item`, `Group`, `Separator`, `Empty` and `Loading` (a
`role="progressbar"`, as cmdk's, to render while items load), the `input` modifier for an
`<input>` of your own (`<input {{c.input}} />`), and `search`, `setSearch`, `value`,
`setValue` and `count`. Each part renders cmdk's attributes (`cmdk-root`, `cmdk-item`,
`cmdk-group-heading`…), so CSS written for cmdk styles it.

### In a dialog

`CommandDialog` puts a `<Command>` in the primitives' modal [Dialog](/primitives/dialog.md):
the overlay (`@overlayClass` for its classes, as cmdk's `overlayClassName`), focus moving into
the input and back, and Escape or a press outside closing it. Its title and description are
visually hidden (`@title`, `@description`). `@hotkey` opens and closes it from anywhere, and it
yields `isOpen`, `open`, `toggle` and `setOpen`, so choosing a command can close it:

<Example @name="command-headless-dialog" @title="A palette on ⌘K" />

```gts
import { fn } from '@ember/helper'
import { Command, CommandDialog } from '@ember-joinery/primitives/command'

<template>
  <CommandDialog @hotkey="mod+k" class="palette" @overlayClass="backdrop" as |d|>
    <Command @onSelect={{fn d.setOpen false}} as |c|>
      <c.Input placeholder="Type a command…" />
      <c.List>…</c.List>
    </Command>
  </CommandDialog>
</template>
```

### In a component

`CommandState` is a command's behaviour, for a component that renders its own parts, as the
styled Command does through the yielded parts. `hotkey` is the modifier behind `@hotkey`
(`{{hotkey "mod+k" this.open}}` on any element), and `matchesHotkey(event, hotkey)` the test it
makes.

### From ember-primitives

| ember-primitives' `CommandPalette`     | Joinery's `Command`                                                       |
| -------------------------------------- | ------------------------------------------------------------------------- |
| `@query`, `@onQueryChange`             | `@search`, `@onSearchChange`                                              |
| `@onSelect` (the event, in a block)    | `@onSelect` (the item's value, and the event)                             |
| `@hotkey`, `@onOpen`                   | the same                                                                  |
| `@resultsText`, the `role="status"`    | the same                                                                  |
| `c.Input`, `c.List`, `l.Item`          | `c.Input`, `c.List`, `c.Item`                                             |
| `l.LinkItem @href`                     | `c.Item @as="a" href=…` (with [properLinks](/primitives/proper-links.md)) |
| `data-active="true"` on the active row | `data-selected="true"` and `aria-selected="true"`                         |
| filtering is yours                     | filtered for you, or `@shouldFilter={{false}}`                            |
| `@items` (a whole palette from a list) | an `{{#each}}` of `c.Item`s, as in the example above                      |
| inside a `<Dialog>`                    | `CommandDialog`, or a `<Command>` in any Dialog                           |
| Home and End move the caret            | Home and End select the first and last item, as cmdk's                    |

## API

| Argument                   | Type                                    | Default | What it does                                         |
| -------------------------- | --------------------------------------- | ------- | ---------------------------------------------------- |
| `@label`                   | `string`                                |         | The input's name, in a visually hidden `<label>`     |
| `@value`                   | `string`                                |         | The selected item's value, controlled                |
| `@defaultValue`            | `string`                                |         | The item selected first                              |
| `@onValueChange`           | `(value: string) => void`               |         | Called when the selection moves                      |
| `@search`                  | `string`                                |         | The input's text, controlled                         |
| `@defaultSearch`           | `string`                                | `''`    | The text it starts with                              |
| `@onSearchChange`          | `(search: string) => void`              |         | Called as the text changes                           |
| `@filter`                  | `(value, search, keywords) => number`   | cmdk's  | Ranks each item; 0 hides it                          |
| `@shouldFilter`            | `boolean`                               | `true`  | `false` shows every item, in order                   |
| `@loop`                    | `boolean`                               | `false` | Whether the arrows wrap round                        |
| `@vimBindings`             | `boolean`                               | `true`  | Whether Ctrl+N, J, P and K move the selection        |
| `@disablePointerSelection` | `boolean`                               | `false` | Whether the pointer leaves the selection alone       |
| `@onSelect`                | `(value: string, event: Event) => void` |         | Called when any item is chosen                       |
| `@resultsText`             | `(count: number) => string`             |         | The status's words                                   |
| `@hotkey`, `@onOpen`       | `string`, `() => void`                  |         | A key combination, and what it calls                 |
| `@as`                      | tag name                                | `div`   | The tag to render                                    |
| `@name`                    | `string`                                |         | Its name, for `CommandHarness` (`data-test-jn-name`) |

The parts take what the styled ones do (see [Command](/components/command.md#api-reference)):
`Item` takes `@value`, `@keywords`, `@disabled`, `@onSelect`, `@forceMount` and `@as`; `Group`
takes `@heading`, `@value` and `@forceMount`; `List` takes `@label`; `Separator` takes
`@alwaysRender`; `Loading` takes `@progress` and `@label`.

## Testing

```ts
import { CommandHarness } from '@ember-joinery/test-support'

const docs = new CommandHarness()
await docs.search('window')
assert.deepEqual(docs.itemValues, ['Dialog'])
assert.strictEqual(docs.status, '1 result')
await docs.press('Enter')
```

See the styled [Command](/components/command.md#testing) for every member.

## Upstream

[cmdk](https://github.com/dip/cmdk) 1.1.1, whose behaviour this follows and whose command score
it ports (MIT; its notice is in `NOTICE`), and ember-primitives'
[CommandPalette](https://github.com/universal-ember/ember-primitives) at 0.64.2.
