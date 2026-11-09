# Avatar

An image element with a fallback for representing the user.

<Example @name="avatar-demo" @title="Avatar" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
components where you use them:

```gts
import { Avatar, AvatarGroup } from '@ember-joinery/ember'
```

## Usage

```gts
<Avatar as |a|>
  <a.Image @src="https://github.com/shadcn.png" alt="@shadcn" />
  <a.Fallback>CN</a.Fallback>
</Avatar>
```

The image renders once it has loaded. Until then, and in its place if it fails, the fallback
shows. It is built on the headless [Avatar](/primitives/avatar.md) in
`@ember-joinery/primitives`, ember-primitives' and Radix's, so you can also give the URL to the
avatar, as ember-primitives does (`<Avatar @src="…">`), and read where the image is from what it
yields (`a.isLoading`, `a.isError`).

## Composition

Use the following composition to build an `Avatar`:

```text
Avatar
├── a.Image
├── a.Fallback
└── a.Badge
```

Use the following composition to build an `AvatarGroup`:

```text
AvatarGroup
├── Avatar
│   ├── a.Image
│   ├── a.Fallback
│   └── a.Badge
├── Avatar
│   ├── a.Image
│   ├── a.Fallback
│   └── a.Badge
└── g.Count
```

## Basic

A basic avatar component with an image and a fallback.

<Example @name="avatar-basic" @title="Basic" />

## Badge

Use the avatar's `Badge` part to add a badge to the avatar. The badge is positioned at the bottom
right of the avatar (the bottom left, right to left).

<Example @name="avatar-badge" @title="Badge" />

Use the `class` attribute to add custom styles to the badge such as custom colors, sizes, etc.

```gts
<Avatar as |a|>
  <a.Image @src="https://github.com/shadcn.png" alt="@shadcn" />
  <a.Fallback>CN</a.Fallback>
  <a.Badge class="bg-green-600 dark:bg-green-800" />
</Avatar>
```

In a Tailwind app, a utility class on the badge wins over its style, as here; without Tailwind,
set `background-color` in your own CSS, which wins too (Joinery's rules are in the `joinery`
layer, below your own).

## Badge with Icon

You can also use an icon inside the `Badge`. A small avatar's badge hides it.

<Example @name="avatar-badge-icon" @title="Badge with Icon" />

## Avatar Group

Use the `AvatarGroup` component to add a group of avatars.

<Example @name="avatar-group" @title="Avatar Group" />

## Avatar Group Count

Use the group's `Count` part to add a count to the group. It takes the size of the group's
avatars.

<Example @name="avatar-group-count" @title="Avatar Group Count" />

## Avatar Group with Icon

You can also use an icon inside the `Count`.

<Example @name="avatar-group-count-icon" @title="Avatar Group with Icon" />

## Sizes

Use `@size` to change the size of the avatar.

<Example @name="avatar-size" @title="Sizes" />

## Dropdown

You can use the `Avatar` component as a trigger for a dropdown menu. Upstream's example
(`avatar-dropdown`) needs Dropdown Menu, which hasn't landed in Joinery yet; it comes with it.

## RTL

Joinery's styles use logical properties, so an avatar lays itself out right to left inside any
element with `dir="rtl"` (see [Direction](/primitives/direction.md)): the badge moves to the
bottom left corner, and a group overlaps from the other side.

<Example @name="avatar-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Avatar

The `Avatar` component is the root component that wraps the avatar image and fallback.

| Argument | Type                        | Default     | What it does                                              |
| -------- | --------------------------- | ----------- | --------------------------------------------------------- |
| `@size`  | `"default" \| "sm" \| "lg"` | `"default"` | How big it is: 32px, 24px (`sm`) or 40px (`lg`), in Nova  |
| `@src`   | `string`                    |             | The image's URL, ember-primitives' way; or give the image |
| `@as`    | tag name                    | `span`      | The tag to render                                         |
| `@name`  | `string`                    |             | Its name, for `AvatarHarness` (`data-test-jn-name`)       |

It yields its parts, and where its image is:

| Yields      | What it is                                                     |
| ----------- | -------------------------------------------------------------- |
| `Image`     | The image (below)                                              |
| `Fallback`  | The fallback (below)                                           |
| `Badge`     | The badge (below)                                              |
| `badge`     | A modifier that makes your own element the badge               |
| `status`    | `"idle"`, `"loading"`, `"loaded"` or `"error"`, Radix's status |
| `isLoading` | Whether the image is loading                                   |
| `isLoaded`  | Whether the image has loaded, and shows                        |
| `isError`   | Whether the image failed to load                               |

### Image

The `Image` part displays the avatar image: an `<img>`, rendered once the image has loaded. It
takes Radix's `AvatarImage` props as arguments, and attributes (`alt`, `class`) on the `<img>`.

| Argument                 | Type               | Default | What it does                                                     |
| ------------------------ | ------------------ | ------- | ---------------------------------------------------------------- |
| `@src`                   | `string`           |         | The image's URL; without it, the avatar's `@src`                 |
| `@crossOrigin`           | `string`           |         | `<img crossorigin>`, for an image from another origin            |
| `@referrerPolicy`        | `string`           |         | `<img referrerpolicy>`                                           |
| `@onLoadingStatusChange` | `(status) => void` |         | Called with each new status: `loading`, then `loaded` or `error` |

### Fallback

The `Fallback` part displays a fallback while the image loads, when it fails, and when there is
none.

| Argument   | Type     | Default | What it does                                                                                         |
| ---------- | -------- | ------- | ---------------------------------------------------------------------------------------------------- |
| `@delayMs` | `number` |         | Wait this long before showing it, so a fast connection never sees it (a new value restarts the wait) |
| `@as`      | tag name | `span`  | The tag to render                                                                                    |

### Badge

The `Badge` part displays a badge indicator on the avatar, positioned at the bottom right. It
takes `@as` (default `span`), and attributes such as `class`.

### AvatarGroup

The `AvatarGroup` component displays a group of avatars with overlapping styling. It takes `@as`
(default `div`) and `@name` (for `AvatarGroupHarness`), and yields `Count`, the count indicator
(`+3`, or an icon), with its modifier, `count`.

### Data attributes

| Part        | Attribute                                 | Value                                                  |
| ----------- | ----------------------------------------- | ------------------------------------------------------ |
| Avatar      | `class`                                   | `jn-avatar`, and `group/avatar`                        |
|             | `data-slot`                               | `avatar`                                               |
|             | `data-size`                               | its `@size`                                            |
|             | `data-loading`, `data-error`              | while the image loads, and if it failed                |
|             | `data-test-jn`, `data-test-jn-name`       | `avatar`, its `@name`                                  |
| Image       | `class`, `data-slot`, `data-test-jn-part` | `jn-avatar-image`, `avatar-image`, `image`             |
| Fallback    | `class`, `data-slot`, `data-test-jn-part` | `jn-avatar-fallback`, `avatar-fallback`, `fallback`    |
| Badge       | `class`, `data-slot`, `data-test-jn-part` | `jn-avatar-badge`, `avatar-badge`, `badge`             |
| AvatarGroup | `class`                                   | `jn-avatar-group`, and `group/avatar-group`            |
|             | `data-slot`, `data-test-jn`               | `avatar-group`                                         |
| Count       | `class`, `data-slot`, `data-test-jn-part` | `jn-avatar-group-count`, `avatar-group-count`, `count` |

## Keyboard interactions

None: an avatar shows a picture and takes no focus. To make one a control, put it inside a
[Button](/components/button.md), as upstream's dropdown example does.

## Accessibility

- Give the image `alt`: the person's name or handle (`alt="@shadcn"`). Upstream's examples leave
  it off in places; Joinery's add it, so they pass the accessibility audit every example runs.
- The fallback is text, so its initials are read while it shows. Where the initials alone don't
  say who it is, put the name beside the avatar, as an [Item](/components/item.md) does.
- The fallback and the count draw `--muted-foreground` on `--muted`, as upstream's do: 4.34:1 in
  the default theme, under the 4.5:1 WCAG AA asks of 14px text. The guide's audits leave those
  two out of the colour-contrast check only, and run every other rule on them. To meet AA,
  darken the text in your own CSS:

  ```css
  [data-slot='avatar-fallback'],
  [data-slot='avatar-group-count'] {
    color: var(--foreground);
  }
  ```

## Testing

`AvatarHarness` from `@ember-joinery/test-support` drives an `<Avatar>`, styled or headless, and
`AvatarGroupHarness` an `<AvatarGroup>`. Tests wait for the image: once `render()` or
`settled()` resolves, it has loaded or failed.

```ts
import { AvatarGroupHarness, AvatarHarness } from '@ember-joinery/test-support'

const avatar = new AvatarHarness('shadcn') // <Avatar @name="shadcn">
assert.true(avatar.isLoaded)
assert.strictEqual(avatar.label, '@shadcn')

const team = new AvatarGroupHarness()
assert.strictEqual(team.avatars.length, 3)
assert.strictEqual(team.count, '+3')
```

| `AvatarHarness` | What it is                                                      |
| --------------- | --------------------------------------------------------------- |
| `status`        | `"idle"`, `"loading"`, `"loaded"` or `"error"`                  |
| `isLoaded`      | Whether the image has loaded, and shows                         |
| `isLoading`     | Whether the image is loading                                    |
| `isError`       | Whether the image failed to load                                |
| `image`         | The `<img>`, once it has loaded, or `null`                      |
| `src`           | The image's URL, once it has loaded, or `null`                  |
| `fallback`      | The fallback while it shows, or `null`                          |
| `fallbackText`  | The fallback's text, or `""`                                    |
| `label`         | What it stands for: the image's `alt`, else the fallback's text |
| `size`          | Its `@size`, or `null` for the headless avatar                  |
| `badge`         | The badge, or `null`                                            |
| `hasBadge`      | Whether it has a badge                                          |

| `AvatarGroupHarness` | What it is                                                    |
| -------------------- | ------------------------------------------------------------- |
| `avatars`            | An `AvatarHarness` for each avatar, in order                  |
| `count`              | The count's text, `""` for an icon, or `null` without a count |
| `countElement`       | The count, or `null`                                          |

## Upstream

shadcn/ui's [Avatar](https://ui.shadcn.com/docs/components/radix/avatar), from
`apps/v4/registry/bases/radix/ui/avatar.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, and
[ember-primitives](https://github.com/universal-ember/ember-primitives)' `Avatar` at 9584c78.
