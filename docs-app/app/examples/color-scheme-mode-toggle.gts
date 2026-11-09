import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { ColorScheme, type ColorSchemePreference } from '@ember-joinery/primitives/color-scheme'
import { service } from '@ember-joinery/primitives/service'

const pressed = (scheme: ColorScheme, preference: ColorSchemePreference) =>
  scheme.preference === preference ? 'true' : 'false'

/** shadcn's mode toggle: light, dark, or the system's. The choice is saved. */
<template>
  {{#let (service ColorScheme) as |scheme|}}
    <div role="group" aria-label="Color scheme">
      <button
        type="button"
        aria-pressed={{pressed scheme "light"}}
        {{on "click" (fn scheme.set "light")}}
      >Light</button>
      <button
        type="button"
        aria-pressed={{pressed scheme "dark"}}
        {{on "click" (fn scheme.set "dark")}}
      >Dark</button>
      <button
        type="button"
        aria-pressed={{pressed scheme "system"}}
        {{on "click" (fn scheme.set "system")}}
      >System</button>
    </div>
    <p>The page is {{scheme.current}}.</p>
  {{/let}}
</template>
