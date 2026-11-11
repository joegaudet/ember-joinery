# Color Scheme

Dark mode, as shadcn's [dark mode](https://ui.shadcn.com/docs/dark-mode) pages set it up with
next-themes: the user picks light, dark or the system's, the choice is saved and synced across
tabs, and `<html>` gets the `dark` class that the theme tokens key off, plus the `color-scheme`
property the browser's own controls and scrollbars follow. It also covers ember-primitives'
color-scheme utility.

<Example @name="color-scheme-mode-toggle" @title="A mode toggle" />

## Usage

There is one `ColorScheme` per app, through [`service`](/primitives/service.md):

```gts
import { ColorScheme, colorScheme } from '@ember-joinery/primitives/color-scheme'
import { service } from '@ember-joinery/primitives/service'

// In a template
<template>
  {{#let (service ColorScheme) as |scheme|}}
    <button type="button" {{on "click" scheme.toggle}}>{{scheme.current}}</button>
  {{/let}}
</template>

// In a component, route or controller
colorScheme(this).set('dark')
```

It applies itself the first time it is asked for. To apply the saved choice when the app boots,
ask for it in the application route, and configure it there if the defaults don't suit:

```ts
// app/routes/application.ts
export default class ApplicationRoute extends Route {
  beforeModel() {
    colorScheme(this).configure({ storageKey: 'my-app-theme' })
  }
}
```

So a dark page doesn't flash light while the app loads, put `colorSchemeScript()`'s output in a
`<script>` in `index.html`'s `<head>`, with the same options.

## API

| Member               | What it is                                                                    |
| -------------------- | ----------------------------------------------------------------------------- |
| `preference`         | What the user chose: `system`, `light` or `dark` (tracked)                    |
| `current`            | The scheme in effect, `light` or `dark` (tracked)                             |
| `system`             | What the system prefers now (tracked)                                         |
| `saved`              | The choice saved for the next visit, or `null` (tracked)                      |
| `isDark`, `isLight`  | `current`, as booleans                                                        |
| `set(preference)`    | Changes the preference, saves it and applies it                               |
| `clear()`            | Forgets the saved choice and goes back to the default preference              |
| `toggle()`           | Switches between light and dark                                               |
| `configure(options)` | Changes the options below                                                     |
| `onChange(listener)` | Calls `listener(current, preference)` on each change; returns the unsubscribe |

| Option                      | Default                | What it does                                            |
| --------------------------- | ---------------------- | ------------------------------------------------------- |
| `storageKey`                | `joinery-color-scheme` | The `localStorage` key, or `null` not to save           |
| `defaultPreference`         | `system`               | The preference before the user chooses                  |
| `element`                   | `<html>`               | Where the class and `color-scheme` go                   |
| `darkClass`                 | `dark`                 | The class set while dark                                |
| `lightClass`                | none                   | A class set while light                                 |
| `disableTransitionOnChange` | `false`                | Turn transitions off for the change, as next-themes can |

`set('system')` saves `system`, as next-themes does, so the next visit follows the system too.
`clear()` removes the saved choice instead.

The module also has ember-primitives' `prefers.dark()`, `prefers.light()`, `prefers.none()`
and `prefers.custom(name)`, and `getColorScheme`, `setColorScheme` and `removeColorScheme`,
which read and write the `color-scheme` property alone, of `<html>` or of the element given
(`setColorScheme('dark')`, `setColorScheme(preview, 'dark')`).

### From ember-primitives

| ember-primitives                                                   | Joinery                                                 |
| ------------------------------------------------------------------ | ------------------------------------------------------- |
| `sync()`                                                           | Nothing to call: it applies itself when first asked for |
| `colorScheme.current`, `isDark`, `isLight`                         | `current`, `isDark`, `isLight`                          |
| `colorScheme.update(value)`                                        | `set(value)`                                            |
| `colorScheme.on.update(fn)`, `colorScheme.off.update(fn)`          | `onChange(fn)`, which returns the unsubscribe           |
| `localPreference.read()`, `isSet()`                                | `saved`, `saved !== null`                               |
| `localPreference.update(value)`, `delete()`                        | `set(value)`, `clear()`                                 |
| `prefers`, `getColorScheme`, `setColorScheme`, `removeColorScheme` | The same names                                          |

## Testing

Each test gets its own `ColorScheme`, which puts `<html>` back when the test ends. What isn't
per test is the machine's own preference and the saved choice, and `setupColorScheme` takes
care of both:

```ts
import { setupColorScheme } from '@ember-joinery/test-support'

module('dark mode', function (hooks) {
  setupRenderingTest(hooks)
  const system = setupColorScheme(hooks, { system: 'light' })

  test('it follows the system', async function (assert) {
    await render(<template><ModeToggle /></template>)
    system.setSystem('dark') // as switching the OS to dark mode
    await settled()
    assert.dom(document.documentElement).hasClass('dark')
  })
})
```

`system.fromAnotherTab('dark')` saves a choice the way another tab would, and `system.stored`
is what is saved.
