# Kbd

Used to display textual user input from keyboard.

<Example @name="kbd-demo" @title="Kbd" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
components where you use them:

```gts
import { Kbd, KbdGroup } from '@ember-joinery/ember'
```

## Usage

```gts
<Kbd>Ctrl</Kbd>
```

## Composition

Use the following composition to build `Kbd` and `KbdGroup`:

```text
Kbd
KbdGroup
├── Kbd
└── Kbd
```

## Group

Use the `KbdGroup` component to group keyboard keys together.

<Example @name="kbd-group" @title="Group" />

## Button

Use the `Kbd` component inside a [`Button`](/components/button.md) to display a keyboard key
inside a button. Mark its side with `data-icon`, as you would an icon's.

<Example @name="kbd-button" @title="Button" />

## Tooltip

You can use the `Kbd` component inside a `Tooltip` component to display a tooltip with a
keyboard key.

<Example @name="kbd-tooltip" @title="Tooltip" />

## Input Group

You can use the `Kbd` component inside an [Input Group](/components/input-group.md)'s addon
(`g.Addon`) to display a keyboard key inside an input group.

<Example @name="kbd-input-group" @title="Input Group" />

## Shortcuts from a string

Joinery's primitives also have [`KeyCombo`](/primitives/keys.md), ember-primitives' shortcut
component: it splits `"ctrl+k"` into its keys and shows the Mac's (`"⌘+k"`) on a Mac. It is
unstyled; `Kbd` and `KbdGroup` are the styled keys.

## RTL

A group's keys run right to left inside any element with `dir="rtl"` (see
[Direction](/primitives/direction.md)), and a key in a button takes the side its `data-icon`
names in that direction.

<Example @name="kbd-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Kbd

Use the `Kbd` component to display a keyboard key.

| Argument | Type     | Default | What it does                                     |
| -------- | -------- | ------- | ------------------------------------------------ |
| `@as`    | tag name | `kbd`   | The tag to render                                |
| `@name`  | `string` |         | Its name, for `KbdHarness` (`data-test-jn-name`) |

```gts
<Kbd>Ctrl</Kbd>
```

### KbdGroup

Use the `KbdGroup` component to group `Kbd` components together.

| Argument | Type     | Default | What it does                                          |
| -------- | -------- | ------- | ----------------------------------------------------- |
| `@as`    | tag name | `kbd`   | The tag to render                                     |
| `@name`  | `string` |         | Its name, for `KbdGroupHarness` (`data-test-jn-name`) |

```gts
<KbdGroup>
  <Kbd>Ctrl</Kbd>
  <Kbd>B</Kbd>
</KbdGroup>
```

Both yield their block and take attributes. Upstream's have no `asChild`, so there is no
modifier.

### Data attributes

| Part     | `class`        | `data-slot` | `data-test-jn` |
| -------- | -------------- | ----------- | -------------- |
| Kbd      | `jn-kbd`       | `kbd`       | `kbd`          |
| KbdGroup | `jn-kbd-group` | `kbd-group` | `kbd-group`    |

Each carries its `@name` as `data-test-jn-name`. An icon in a key without a `size-` class is
drawn at `size-3`.

## Keyboard interactions

Keys are shown, not used: a `Kbd` takes no focus and lets presses through
(`pointer-events: none`), so one inside a button is part of the button.

## Accessibility

- A `<kbd>` is what assistive technology and browsers expect for keyboard input, and a `<kbd>`
  of `<kbd>`s (a `KbdGroup`) is one input of several keys.
- Symbols such as `⌘` and `⏎` are read by their names, which some screen readers don't know.
  Where it matters, give the key a name: `<Kbd aria-label="Command">⌘</Kbd>`.
- Upstream's colours, `--muted-foreground` on `--muted`, give about 4.3:1 in the default light
  theme (from 3.9:1 in Olive to 4.5:1 in Mauve), under the 4.5:1 WCAG AA asks of the keys'
  12px text. Joinery keeps upstream's colours, and its tests audit everything around the keys.
  To meet AA, darken the keys' text in your CSS, which wins over Joinery's:

  ```css
  .jn-kbd:not([data-slot='tooltip-content'] *) {
    color: color-mix(in oklab, var(--muted-foreground), var(--foreground) 20%);
  }
  ```

## Testing

`KbdHarness` and `KbdGroupHarness` from `@ember-joinery/test-support` find a key
(`data-test-jn="kbd"`) and a group (`data-test-jn="kbd-group"`):

```ts
import { ButtonHarness, KbdGroupHarness, KbdHarness } from '@ember-joinery/test-support'

assert.strictEqual(new ButtonHarness().find(KbdHarness).label, '⏎')
const bold = new KbdGroupHarness('bold')
assert.deepEqual(bold.keys, ['Ctrl', 'B'])
```

| Harness           | Member  | What it is                                        |
| ----------------- | ------- | ------------------------------------------------- |
| `KbdHarness`      | `label` | The key's label, as shown                         |
| `KbdGroupHarness` | `keys`  | Each key's label, in order                        |
|                   | `kbds`  | Each key's `KbdHarness`, in order                 |
|                   | `label` | Everything it shows, keys and what's between them |

## Upstream

shadcn/ui's [Kbd](https://ui.shadcn.com/docs/components/radix/kbd), from
`apps/v4/registry/bases/radix/ui/kbd.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
