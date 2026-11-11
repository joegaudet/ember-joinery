# Avatar

An image with a fallback, for representing a user: ember-primitives' `Avatar` and Radix's. The
image renders only once it has loaded; until then, and in its place if it fails, the fallback
shows, after a delay if you give one. It has no styles; the styled
[Avatar](/components/avatar.md) is built on it.

<Example @name="avatar-headless" @title="ember-primitives' avatars" />

## Usage

```gts
import { Avatar } from '@ember-joinery/primitives/avatar'

<template>
  {{! ember-primitives' way: the URL on the avatar }}
  <Avatar @src={{this.user.photo}} as |a|>
    <a.Image alt={{this.user.name}} />
    <a.Fallback @delayMs={{600}}>{{this.user.initials}}</a.Fallback>
  </Avatar>

  {{! Radix's way: the URL on the image }}
  <Avatar as |a|>
    <a.Image @src="https://github.com/shadcn.png" alt="@shadcn" />
    <a.Fallback>CN</a.Fallback>
  </Avatar>
</template>
```

The avatar yields where its image is (`status`, and `isLoading`, `isLoaded` and `isError`), so
the block can show something of its own while it loads. The root is `data-loading` while the
image loads and `data-error` if it failed, for CSS.

`ImageLoader` loads one image off the page, as Radix's `useImageLoadingStatus` does, for code of
your own:

```ts
import { ImageLoader } from '@ember-joinery/primitives/avatar'

const loader = new ImageLoader(url, { crossOrigin: 'anonymous' })
loader.status // 'loading', then 'loaded' or 'error' (tracked)
loader.subscribe(status => console.log(status))
loader.destroy()
```

## API

### Avatar

| Argument | Type     | Default | What it does                                        |
| -------- | -------- | ------- | --------------------------------------------------- |
| `@src`   | `string` |         | The image's URL; or give it to the image            |
| `@as`    | tag name | `span`  | The tag to render                                   |
| `@name`  | `string` |         | Its name, for `AvatarHarness` (`data-test-jn-name`) |

It yields `Image`, `Fallback`, `status` (`"idle"`, `"loading"`, `"loaded"` or `"error"`),
`isLoading`, `isLoaded` and `isError`, and takes attributes.

### Image

An `<img>`, rendered once its image has loaded, with `data-test-jn-part="image"` and the
attributes you give it (`alt`, `class`).

| Argument                 | Type               | What it does                                                     |
| ------------------------ | ------------------ | ---------------------------------------------------------------- |
| `@src`                   | `string`           | The image's URL; without it, the avatar's `@src`                 |
| `@crossOrigin`           | `string`           | How the image is fetched, and `<img crossorigin>`                |
| `@referrerPolicy`        | `string`           | The same, and `<img referrerpolicy>`                             |
| `@onLoadingStatusChange` | `(status) => void` | Called with each new status: `loading`, then `loaded` or `error` |

### Fallback

A `span` (or `@as`) with `data-test-jn-part="fallback"`, shown while the image isn't loaded.

| Argument   | Type     | What it does                                                                                         |
| ---------- | -------- | ---------------------------------------------------------------------------------------------------- |
| `@delayMs` | `number` | Wait this long before showing it, so a fast connection never sees it (a new value restarts the wait) |
| `@as`      | tag name | The tag to render                                                                                    |

## Accessibility

Give the image `alt`. Neither the avatar nor the image adds one: a missing `alt` fails your
accessibility audit, as it should. The fallback is text, read while it shows.

## Testing

Tests wait for the image: once `render()` or `settled()` resolves, it has loaded or failed (and
a fallback's `@delayMs` has passed). `AvatarHarness` reads it:

```ts
import { AvatarHarness } from '@ember-joinery/test-support'

const avatar = new AvatarHarness()
avatar.status // 'loaded' or 'error'
avatar.label // the image's alt, or the fallback's text
```

The [Avatar](/components/avatar.md#testing) page lists its members. To see the loading state in
a test, swap `window.Image` for a stand-in whose `load` event you fire yourself, as Joinery's own
tests do.

## Upstream

[ember-primitives](https://github.com/universal-ember/ember-primitives)' `Avatar` at 9584c78,
and Radix's `Avatar` (`@radix-ui/react-avatar`), which shadcn/ui's Avatar renders.
