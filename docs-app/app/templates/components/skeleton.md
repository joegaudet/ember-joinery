# Skeleton

Use to show a placeholder while content is loading.

<Example @name="skeleton-demo" @title="Skeleton" />

## Installation

```bash
pnpm add @ember-joinery/ember
```

Import Joinery's CSS once (see [Installation](/getting-started/installation.md)), then the
component where you use it:

```gts
import { Skeleton } from '@ember-joinery/ember'
```

## Usage

```gts
<Skeleton class="h-[20px] w-[100px] rounded-full" />
```

A skeleton has no size of its own: give it one with utility classes in a Tailwind app, as
here, or with your own CSS, which wins over Joinery's (its rules are in the `joinery` layer).

## Avatar

<Example @name="skeleton-avatar" @title="Avatar" />

## Card

Skeletons in a [card](/components/card.md), standing in for its title, description and image.

<Example @name="skeleton-card" @title="Card" />

## Text

<Example @name="skeleton-text" @title="Text" />

## Form

<Example @name="skeleton-form" @title="Form" />

## Table

<Example @name="skeleton-table" @title="Table" />

## RTL

Skeletons lay themselves out right to left inside any element with `dir="rtl"` (see
[Direction](/primitives/direction.md)).

<Example @name="skeleton-rtl" @title="RTL" @dir="rtl" />

## API Reference

### Skeleton

| Argument | Type     | Default | What it does                                          |
| -------- | -------- | ------- | ----------------------------------------------------- |
| `@as`    | tag name | `div`   | The tag to render, such as `span` in a line of text   |
| `@name`  | `string` |         | Its name, for `SkeletonHarness` (`data-test-jn-name`) |

It yields its block and takes attributes. Upstream's has no `asChild`, so there is no modifier.

### Data attributes

| Attribute           | Value         |
| ------------------- | ------------- |
| `class`             | `jn-skeleton` |
| `data-slot`         | `skeleton`    |
| `data-test-jn`      | `skeleton`    |
| `data-test-jn-name` | its `@name`   |

It is a rounded block in the theme's `--muted` (`rounded-md` in Nova; each style has its own
radius), pulsing with `animate-pulse`.

## Keyboard interactions

A skeleton takes no focus and has no keys.

## Accessibility

- A skeleton is a picture of the layout to come, and says nothing to assistive technology. Mark
  the region that is loading with `aria-busy="true"` while it shows skeletons, and take it off
  (or announce the result in a live region) when the content arrives.
- The pulse is a CSS animation; add your own `prefers-reduced-motion` rule to stop it.

## Testing

`SkeletonHarness` from `@ember-joinery/test-support` finds a skeleton
(`data-test-jn="skeleton"`). It has no ARIA, so a test counts and measures them:

```ts
import { SkeletonHarness } from '@ember-joinery/test-support'

assert.strictEqual(SkeletonHarness.findAll().length, 3)
assert.strictEqual(new SkeletonHarness('avatar').width, 48)
```

| Member      | What it is                         |
| ----------- | ---------------------------------- |
| `width`     | Its laid-out width, in CSS pixels  |
| `height`    | Its laid-out height, in CSS pixels |
| `isPulsing` | Whether its animation runs         |

## Upstream

shadcn/ui's [Skeleton](https://ui.shadcn.com/docs/components/radix/skeleton), from
`apps/v4/registry/bases/radix/ui/skeleton.tsx` at shadcn-ui/ui@8ab2771, in the Nova style.
