# Toast

sonner's toasts, headless: `toast()` to show one from anywhere, and `<Toaster>` to render them.
It is what [Sonner](/components/sonner.md) is built on, with sonner's markup and data
attributes, and without its look: `@ember-joinery/ember`'s `joinery.css` carries sonner's CSS,
and its `Toaster` adds shadcn's tokens and lucide's icons.

<Example @name="toast-headless" @title="A Toaster of its own" />

## Usage

```gts
import { on } from '@ember/modifier'
import { Toaster, toast } from '@ember-joinery/primitives/toast'

const save = () => toast.success('Saved')

<template>
  <button type="button" {{on "click" save}}>Save</button>
  <Toaster @position="top-center" />
</template>
```

`toast()` and its methods (`success`, `info`, `warning`, `error`, `loading`, `message`,
`custom`, `promise`, `dismiss`, `getHistory`, `getToasts`) are sonner's, and so are the
Toaster's arguments: the [Sonner](/components/sonner.md#api-reference) page lists them all.

## Toasts belong to the app

sonner keeps one list of toasts for the page. Joinery keeps one per owner, a `Toasts`
[service](/primitives/service.md): each app instance has its own, and so does each test, and
they go with their owner, timers and all.

- A rendered `<Toaster>` points `toast()` at its owner, until it goes. With several, the newest
  wins.
- `toastsFor(this)` is the `Toasts` of anything with an owner (a component, a route, a test's
  `this.owner`). It has the same methods as `toast`, and `toasts`, the list the Toasters show,
  newest first (sonner's `useSonner().toasts`). A change reaches `toasts` a microtask later, as
  sonner's Toaster gets its toasts a tick later, so `toast()` can be called while a page
  renders; `getToasts()` has a new toast at once.
- `toastOwner()` says which owner `toast()` uses now. Before a Toaster renders, and in a test
  with `setupToaster(hooks)`, it is `globalThis.JOINERY_TOAST_OWNER`, which test-support sets
  to each test's owner.

A toast made with no Toaster and no owner goes nowhere, as in sonner, and Ember warns in
development.

## What the Toaster renders

A `<section>` live region (`aria-live="polite"`), always there so screen readers hear what is
added to it, and inside it one `<ol data-sonner-toaster>` per position in use, each holding its
toasts as `<li data-sonner-toast>`. The data attributes are sonner's (`data-mounted`,
`data-front`, `data-expanded`, `data-removed`, `data-swiping`…), and so are the custom
properties each toast is placed with (`--offset`, `--initial-height`, `--z-index`), set through
the CSSOM so a strict Content Security Policy doesn't block them. sonner's CSS reads them to
stack, expand and animate the toasts; without it the toasts are a plain list.

Each list is in the [top layer](/primitives/top-layer.md), so toasts show above dialogs and
popovers, and it moves back to the top when a toast arrives. It is a
[dismissable branch](/primitives/dismiss.md): pressing a toast closes no layer. The browser's
popover styles apply to it; `joinery.css` undoes them.

## Behaviour

- **Timers.** A toast closes after its `duration` (4 seconds, or the Toaster's `@duration`),
  paused while the pointer or the keyboard's focus is on the stack and while the page is
  hidden. Loading
  toasts, promises that haven't settled, and `duration: Infinity` have none.
- **The stack.** The newest is in front and three show (`@visibleToasts`); the rest wait behind.
  Hovering, the hotkey (Alt+T) or tabbing to a toast expands it; `@expand` keeps it expanded.
  Keyboard focus (`:focus-visible`) holds it open until focus leaves; the focus a click or a tap
  gives a toast doesn't, so the stack collapses when the pointer leaves, as in sonner.
- **Swipe to dismiss.** A pointer drag of 45px, or a quick flick, towards one of its position's
  sides (or `@swipeDirections`) dismisses it; the other way, it follows the pointer less and
  springs back.
- **Promises.** `toast.promise()` shows `loading` until the promise settles, then `success` or
  `error` in its place. A resolved `Response` that isn't `ok`, or an `Error`, is a failure. It
  returns `{ id, unwrap }` (sonner's returns the id, with `unwrap` on it), and `toast.dismiss()`
  takes either.

## API

| Export                                                     | What it is                                                         |
| ---------------------------------------------------------- | ------------------------------------------------------------------ |
| `toast`                                                    | sonner's `toast`, for the current app                              |
| `Toaster`                                                  | The headless Toaster (sonner's props as arguments)                 |
| `toastsFor(context)`                                       | The `Toasts` of `context`'s owner                                  |
| `Toasts`                                                   | The per-owner class: `toasts`, `history` and `toast`'s methods     |
| `toastOwner()`                                             | The owner `toast()` uses now, or `undefined`                       |
| `bindToasts(owner)`                                        | Points `toast()` at an owner (a Toaster does it); returns the undo |
| `TOAST_LIFETIME`, `SWIPE_THRESHOLD`, `TIME_BEFORE_UNMOUNT` | sonner's 4000ms, 45px and 200ms                                    |

## Testing

`setupToaster(hooks)`, `ToasterHarness` and `ToastHarness` from `@ember-joinery/test-support`
work with this Toaster as with Joinery's styled one; the [Sonner](/components/sonner.md#testing)
page lists their members.

## Upstream

[sonner](https://github.com/emilkowalski/sonner) 2.0.7, the version shadcn/ui's Sonner renders
at shadcn-ui/ui@8ab2771: its `toast` state, `Toaster` and `Toast`. ember-primitives has no
toast. sonner is MIT licensed, © 2023 Emil Kowalski; its notice is in Joinery's `NOTICE` and
in the built files that carry its code (this module, and `@ember-joinery/ember`'s CSS).
