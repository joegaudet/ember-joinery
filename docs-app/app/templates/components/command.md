# Command

Command menu for search and quick actions.

<Example @name="command-demo" @title="Command" @align="start" />

## About

Upstream's `<Command />` uses the [`cmdk`](https://github.com/dip/cmdk) component by
[Dip](https://www.dip.org/). Joinery's is built on its own headless
[Command](/primitives/command.md), which does what cmdk does: it filters and ranks the items as
you type, with cmdk's own scoring, and moves the selection with the keys.

## Installation

```bash
pnpm add @ember-joinery/ember lucide
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Command, CommandDialog } from '@ember-joinery/ember'
```

## Usage

```gts
<Command class="max-w-sm rounded-lg border" as |c|>
  <c.Input placeholder="Type a command or search..." />
  <c.List>
    <c.Empty>No results found.</c.Empty>
    <c.Group @heading="Suggestions">
      <c.Item>Calendar</c.Item>
      <c.Item>Search Emoji</c.Item>
      <c.Item>Calculator</c.Item>
    </c.Group>
    <c.Separator />
    <c.Group @heading="Settings">
      <c.Item>Profile</c.Item>
      <c.Item>Billing</c.Item>
      <c.Item>Settings</c.Item>
    </c.Group>
  </c.List>
</Command>
```

An item's value is its text (each run of spaces one space), or its `@value`. Typing filters the
items by it, and its `@keywords` too, and shows the best matches first: in each group, and the
groups by their best item. A group with nothing left hides, the separators hide while there is
a search, and Empty shows when nothing matches. Choose an item with a click or Enter: its
`@onSelect` hears its value, and so does the command's.

## Composition

Use the following composition to build a `Command`:

```text
Command
├── c.Input
└── c.List
    ├── c.Empty
    ├── c.Group
    │   ├── c.Item
    │   └── c.Item
    ├── c.Separator
    └── c.Group
        ├── c.Item
        └── c.Item
```

`<Command>` yields its parts, and `c.Shortcut` for an item's shortcut. `CommandDialog` is its
own component: put a `<Command>` in it.

## Basic

A simple command menu in a dialog.

<Example @name="command-basic" @title="Basic" />

Upstream's button sets the dialog's `open`; here it calls `setOpen` with `{{on "click"}}`, and
`@onOpenChange` hears the dialog close itself (Escape, a press outside).

## Shortcuts

<Example @name="command-shortcuts" @title="Shortcuts" />

A `c.Shortcut` is text at the end of the item (`⌘P`), not a key binding. Its text is part of
the item's value, as in cmdk, so the value of Profile is `Profile ⌘P`.

## Groups

A command menu with groups, icons and separators.

<Example @name="command-groups" @title="Groups" />

## Scrollable

Scrollable command menu with multiple items.

<Example @name="command-scrollable" @title="Scrollable" />

The selection scrolls into view as the keys move it, its group's heading with it at the top
of a group.

## RTL

Joinery's styles use logical properties, so a command lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)): the search icon starts
the input on the right, and the shortcuts end the items on the left. The keys are the same.

<Example @name="command-rtl" @title="RTL" @dir="rtl" @align="start" />

## API Reference

### Command

| Argument                   | Type                                    | Default                 | What it does                                                        |
| -------------------------- | --------------------------------------- | ----------------------- | ------------------------------------------------------------------- |
| `@label`                   | `string`                                |                         | The input's name for screen readers, in a visually hidden `<label>` |
| `@value`                   | `string`                                |                         | The selected item's value, when you control it                      |
| `@defaultValue`            | `string`                                | the first item          | The item selected first, when it controls itself                    |
| `@onValueChange`           | `(value: string) => void`               |                         | Called when the selection moves                                     |
| `@search`                  | `string`                                |                         | The input's text, when you control it                               |
| `@defaultSearch`           | `string`                                | `''`                    | The text it starts with                                             |
| `@onSearchChange`          | `(search: string) => void`              |                         | Called as the text changes                                          |
| `@filter`                  | `(value, search, keywords) => number`   | cmdk's                  | Ranks each item; 0 hides it                                         |
| `@shouldFilter`            | `boolean`                               | `true`                  | `false` shows every item, in order, for items you filter yourself   |
| `@loop`                    | `boolean`                               | `false`                 | Whether the arrows wrap round                                       |
| `@vimBindings`             | `boolean`                               | `true`                  | Whether Ctrl+N, J, P and K move the selection                       |
| `@disablePointerSelection` | `boolean`                               | `false`                 | Whether the pointer leaves the selection alone                      |
| `@onSelect`                | `(value: string, event: Event) => void` |                         | Called when any item is chosen                                      |
| `@resultsText`             | `(count: number) => string`             | `1 result`, `3 results` | What screen readers hear as the results change                      |
| `@hotkey`                  | `string`                                |                         | A key combination that calls `@onOpen` from anywhere: `"mod+k"`     |
| `@onOpen`                  | `() => void`                            |                         | Called when `@hotkey` is pressed                                    |
| `@as`                      | tag name                                | `div`                   | The tag to render                                                   |
| `@name`                    | `string`                                |                         | Its name, for `CommandHarness` (`data-test-jn-name`)                |

It yields its parts (`Input`, `List`, `Empty`, `Group`, `Item`, `Separator`, `Shortcut`), the
`input` modifier for an `<input>` of your own, and `search`, `setSearch`, `value`, `setValue`
and `count`, the number of results.

### Input

| Argument      | Type            | Default           | What it does                                    |
| ------------- | --------------- | ----------------- | ----------------------------------------------- |
| `@searchIcon` | a `lucide` icon | lucide's `search` | The icon at its start (upstream's `SearchIcon`) |

Its attributes, such as `placeholder`, go on the `<input>`.

### List

| Argument | Type     | Default       | What it does                |
| -------- | -------- | ------------- | --------------------------- |
| `@label` | `string` | `Suggestions` | Its name for screen readers |
| `@as`    | tag name | `div`         | The tag to render           |

### Group

| Argument      | Type      | Default    | What it does                                   |
| ------------- | --------- | ---------- | ---------------------------------------------- |
| `@heading`    | `string`  |            | Its heading, which also names its items' group |
| `@value`      | `string`  | `@heading` | Its `data-value`                               |
| `@forceMount` | `boolean` | `false`    | Show it whatever the search                    |

### Item

| Argument      | Type                      | Default          | What it does                                           |
| ------------- | ------------------------- | ---------------- | ------------------------------------------------------ |
| `@value`      | `string`                  | its text         | What the search matches and `@onSelect` hears          |
| `@keywords`   | `string[]`                |                  | More words to match it by                              |
| `@disabled`   | `boolean`                 | `false`          | It shows, but can't be selected or chosen              |
| `@onSelect`   | `(value: string) => void` |                  | Called when it is chosen                               |
| `@forceMount` | `boolean`                 | `false`          | Show it whatever the search                            |
| `@checkIcon`  | a `lucide` icon           | lucide's `check` | The check at its end, shown with `data-checked="true"` |
| `@as`         | tag name                  | `div`            | The tag to render: `a` (with an `href`) for a link     |

### Separator

| Argument        | Type      | Default | What it does                |
| --------------- | --------- | ------- | --------------------------- |
| `@alwaysRender` | `boolean` | `false` | Show it during a search too |

### CommandDialog

| Argument           | Type                      | Default                          | What it does                                 |
| ------------------ | ------------------------- | -------------------------------- | -------------------------------------------- |
| `@open`            | `boolean`                 |                                  | Whether it is open, when you control it      |
| `@defaultOpen`     | `boolean`                 | `false`                          | Whether it starts open                       |
| `@onOpenChange`    | `(open: boolean) => void` |                                  | Called when it opens or closes, or asks to   |
| `@title`           | `string`                  | `Command Palette`                | Its name for screen readers, visually hidden |
| `@description`     | `string`                  | `Search for a command to run...` | Its description, visually hidden             |
| `@showCloseButton` | `boolean`                 | `false`                          | Show the dialog's close button               |
| `@closeLabel`      | `string`                  | `Close`                          | That button's name for screen readers        |
| `@closeIcon`       | a `lucide` icon           | lucide's `x`                     | That button's icon                           |
| `@hotkey`          | `string`                  |                                  | Opens and closes it from anywhere: `"mod+k"` |
| `@modal`           | `boolean`                 | `true`                           | Whether it is modal                          |
| `@name`            | `string`                  |                                  | Its name, for `CommandDialogHarness`         |

It yields `isOpen`, `open`, `toggle` and `setOpen`, so a command inside can close it:
`<Command @onSelect={{fn d.setOpen false}}>`. Its attributes, such as `class`, go on the
dialog. `mod` in `@hotkey` is ⌘ on a Mac and Ctrl elsewhere.

### Data attributes

| Part        | `class`                                 | `data-slot`         | Also                                                           |
| ----------- | --------------------------------------- | ------------------- | -------------------------------------------------------------- |
| Root        | `jn-command`                            | `command`           | `cmdk-root`, `data-test-jn="command"`                          |
| Input       | `jn-command-input`                      | `command-input`     | `cmdk-input`, `role="combobox"`, `aria-activedescendant`       |
| Input group | `jn-input-group jn-command-input-group` | `input-group`       | and its wrapper, `jn-command-input-wrapper`                    |
| List        | `jn-command-list`                       | `command-list`      | `cmdk-list`, `role="listbox"` while it holds options           |
| Group       | `jn-command-group`                      | `command-group`     | `cmdk-group`, `hidden` while it has no results                 |
| Item        | `jn-command-item`                       | `command-item`      | `cmdk-item`, `data-selected`, `data-disabled`, `data-value`    |
| Separator   | `jn-command-separator`                  | `command-separator` | `cmdk-separator`                                               |
| Empty       | `jn-command-empty`                      | `command-empty`     | `cmdk-empty`                                                   |
| Shortcut    | `jn-command-shortcut`                   | `command-shortcut`  |                                                                |
| Dialog      | `jn-dialog-content jn-command-dialog`   | `dialog-content`    | the Dialog's, with `data-test-jn="command-dialog"` on its root |

`data-selected` and `data-disabled` are `true` or `false`, as cmdk's. While a search ranks the
items, each has `aria-posinset` and `aria-setsize` for the order they show in.

## Keyboard interactions

| Key                                      | What it does                                                  |
| ---------------------------------------- | ------------------------------------------------------------- |
| `ArrowDown`, `ArrowUp`                   | Selects the next or previous item, passing over disabled ones |
| `Ctrl` + `N` or `J`, `Ctrl` + `P` or `K` | The same, unless `@vimBindings={{false}}`                     |
| `Alt` + `ArrowDown`, `Alt` + `ArrowUp`   | Selects the first item of the next or previous group          |
| `Home`, `End`                            | Selects the first or last item                                |
| `⌘` + `ArrowUp`, `⌘` + `ArrowDown`       | The same                                                      |
| `Enter`                                  | Chooses the selected item, with a click                       |
| `Esc`                                    | In a CommandDialog: closes it, and focus goes back            |

Focus stays in the input throughout; the selection is what moves, as the
[APG combobox pattern](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/) has it for a list
that autocompletes. The other keys type.

## Accessibility

- The input is a combobox over the list (`aria-controls`), and names the selected item in
  `aria-activedescendant`, so a screen reader reads it as the selection moves. Name the input:
  with `@label`, an `aria-label`, or at least a `placeholder`.
- A `role="status"`, visually hidden, says how many results there are as you type (`3
results`), as ember-primitives' CommandPalette does. Give `@resultsText` in the page's
  language.
- Groups are `role="group"`, named by their headings. A listbox holds only options and
  groups, so the separators are hidden from screen readers (upstream's are
  `role="separator"`), and while nothing matches the list is a plain element around Empty.
- CommandDialog names itself with its visually hidden `@title`; Joinery puts the title and
  description inside the dialog, where upstream renders them beside it.

## Testing

`CommandHarness` from `@ember-joinery/test-support` drives a `<Command>`, and
`CommandDialogHarness` a `<CommandDialog>`, with the command inside as `command`:

```ts
import { CommandDialogHarness, CommandHarness } from '@ember-joinery/test-support'

const command = new CommandHarness()
await command.search('cal')
assert.deepEqual(command.itemValues, ['Calendar', 'Calculator'])
await command.press('ArrowDown')
assert.strictEqual(command.selected, 'Calculator')
await command.press('Enter')

const palette = new CommandDialogHarness()
await palette.pressHotkey('mod+k')
await palette.command.search('settings')
```

| Member                  | What it is                                                   |
| ----------------------- | ------------------------------------------------------------ |
| `input`, `list`         | The search box and the list                                  |
| `items`                 | The items shown, in the order they show                      |
| `itemValues`, `texts`   | Their values, and their text                                 |
| `item(value)`           | The item with that value                                     |
| `hasItem(value)`        | Whether it is shown                                          |
| `selected`              | The selected item's value (`aria-selected`), or `null`       |
| `activeItem`            | The item the input's `aria-activedescendant` names           |
| `isSelected(value)`     | Whether that item is selected                                |
| `isDisabled(value)`     | Whether that item is disabled (`aria-disabled`)              |
| `groups`, `headings`    | The groups shown, and their headings, in the order they show |
| `groupValues(heading)`  | The values of the items shown in that group                  |
| `separators`            | The separators shown                                         |
| `empty`, `isEmpty`      | Empty, while nothing matches                                 |
| `status`                | What the `role="status"` says                                |
| `query`, `hasFocus`     | The input's text, and whether focus is in it                 |
| `search(text)`          | Types a search                                               |
| `clear()`               | Empties the search box                                       |
| `press(key, modifiers)` | Presses a key in the search box                              |
| `hover(value)`          | Moves the pointer over an item                               |
| `choose(value)`         | Clicks an item                                               |

`CommandDialogHarness` is a [`DialogHarness`](/components/dialog.md#testing), with `command`
and `pressHotkey(hotkey)`.

## Upstream

shadcn/ui's [Command](https://ui.shadcn.com/docs/components/radix/command), from
`apps/v4/registry/bases/radix/ui/command.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, on
cmdk 1.1.1. The headless part is [Command](/primitives/command.md) in
`@ember-joinery/primitives`, which covers ember-primitives' CommandPalette too.

Where Joinery's differs, and why:

- **Ranking.** cmdk moves the ranked items' elements; Glimmer owns them, so they keep their
  place in the DOM and show in order through CSS `order` (their container a column of flex
  items), and the keys follow the order they show in. When the search clears, they go back to
  their own order; cmdk leaves them where the last search put them.
- **The input group's border.** Upstream passes `cn-command-input-group` to its InputGroup's
  `cn()`, after the group's own classes, so the Command's rule wins: in the Nova and Vega styles
  a fainter border (`border-input/30`), and in Lyra none. Joinery's style sheets keep upstream's
  rules in upstream's order, which in those three styles puts the InputGroup's rule after the
  Command's, so there the group keeps InputGroup's border.
