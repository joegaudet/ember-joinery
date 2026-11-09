# Shadowed

Render content in a shadow DOM, attached to a div. It uses the [shadow
DOM](https://developer.mozilla.org/en-US/docs/Web/API/Web_components/Using_shadow_DOM) API, and
is useful when you want to render content that escapes your app's styles. It is
ember-primitives' `Shadowed`.

## Example

<Example @name="shadowed-demo" @title="Styles stop at the shadow root" />

## Usage

```gts
import { Shadowed } from '@ember-joinery/primitives/shadowed'

<template>
  <Shadowed>
    <p class="card">Not styled by the app's .card</p>
  </Shadowed>
</template>
```

The content is still the component's: its state, its actions and its destruction. Only the
styles stop at the shadow boundary. The attributes go on the outer `<div>`; the shadow root's
host is a `<div>` inside it, and the content renders in a `<div>` inside the shadow root, as in
ember-primitives (Ember can't render straight into a shadow root on every version Joinery
supports). Joinery's layout primitives inside one (a Zoetrope, a StickyFooter) bring their
rules into it.

## API

| Argument         | Type      | Default | What it does                                                                       |
| ---------------- | --------- | ------- | ---------------------------------------------------------------------------------- |
| `@includeStyles` | `boolean` | `false` | Bring the page's style sheets in: a copy of each in `<head>`, and its adopted ones |
| `@name`          | `string`  |         | Its name, for its harness                                                          |

### From ember-primitives

The same component. With `@includeStyles`, ember-primitives `@import`s the `href` of each
`<link>` on the page; Joinery copies each `<style>` and `<link rel="stylesheet">` in `<head>`,
so the styles a dev server injects come too, and adopts the page's constructed style sheets.
The copies render at the start of the content's `<div>`. When `@includeStyles` turns off, both
go again.

## Testing

Harnesses don't look into shadow roots, so `ShadowedHarness` finds what is rendered there.
`@ember-joinery/test-support` also has ember-primitives' shadow DOM helpers.

```ts
import {
  ShadowedHarness,
  findInShadow,
  findShadow,
  findInFirstShadow,
  hasShadowRoot,
} from '@ember-joinery/test-support'

const preview = new ShadowedHarness('preview') // <Shadowed @name="preview">
preview.query('h1') // also queryAll(selector)
preview.text // what a reader sees: the CSS of a copied <style> is left out
preview.shadowRoot // also host, content, styleSheetCount

findInShadow('[data-preview]', 'h1') // in the shadow root of an element or a selector
findShadow() // the first element with a shadow root in the test
findInFirstShadow('h1')
hasShadowRoot(element)
```
