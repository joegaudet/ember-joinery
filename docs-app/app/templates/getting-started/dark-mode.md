# Dark Mode

Adding dark mode to your app.

Joinery's dark mode is shadcn's: the theme's tokens have a dark value each, set on the `dark`
class, so `dark` on `<html>` turns the whole page dark (on any other element, the part of the
page inside it). Where shadcn's pages add a theme provider for each framework, Joinery has one
for every Ember app: `ColorScheme`, from
[`@ember-joinery/primitives/color-scheme`](/primitives/color-scheme.md). It follows the system,
saves the user's choice, keeps tabs in sync, and sets the class and the `color-scheme` property
the browser's own controls and scrollbars follow.

<Example @name="dark-mode-toggle" @title="A mode toggle" @align="start" />

## Apply the choice when the app boots

`ColorScheme` is owned by the app, so there is one for each app (and each test). It applies
itself the first time it is asked for, so ask for it in the application route, and configure it
there if the defaults don't suit:

```ts
// app/routes/application.ts
import Route from '@ember/routing/route'
import { colorScheme } from '@ember-joinery/primitives/color-scheme'

export default class ApplicationRoute extends Route {
  beforeModel() {
    colorScheme(this).configure({ storageKey: 'my-app-theme' })
  }
}
```

So a dark page doesn't flash light while the app loads, apply the saved choice before it does,
with `colorSchemeScript()`'s output in a `<script>` in `index.html`'s `<head>` (with the same
options, if you configured any).

## Add a mode toggle

Place a mode toggle on your site, as the example above does: an outline icon
[Button](/components/button.md) that opens a [Dropdown Menu](/components/dropdown-menu.md) of
Light, Dark and System, each calling `scheme.set` with its choice, which changes the
preference, saves it and applies it. A plain switch between the two takes less:

```gts
import { on } from '@ember/modifier'
import { Button } from '@ember-joinery/ember'
import { ColorScheme } from '@ember-joinery/primitives/color-scheme'
import { service } from '@ember-joinery/primitives/service'

<template>
  {{#let (service ColorScheme) as |scheme|}}
    <Button @variant="outline" {{on "click" scheme.toggle}}>
      {{if scheme.isDark "Light mode" "Dark mode"}}
    </Button>
  {{/let}}
</template>
```

`scheme.current` is the scheme in effect, `light` or `dark`, and `scheme.preference` what the
user chose, `system` included. The [Color Scheme](/primitives/color-scheme.md) page has the rest
of its API.

## Styling for dark mode

Joinery's components need nothing more: their colours are the tokens. For your own CSS, use the
tokens too (`background: var(--card)`), and they follow. In a Tailwind app, Joinery's
`tailwind.css` adds shadcn's `dark:` variant, which matches inside the `dark` class, so
`dark:bg-input/30` works as on ui.shadcn.com. The example's icons use it: the sun turns away and
the moon in when the page is dark.

The [Theme Builder](/getting-started/theme-builder.md) edits the dark tokens alongside the light
ones, and every example's frame has a Dark switch, which shows that one example dark.

## Testing

Each test gets its own `ColorScheme`, which puts `<html>` back when the test ends.
`setupColorScheme` also isolates what isn't per test, the machine's own preference and the
saved choice:

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

The example's **Test** tab has the whole test, menu and all.

## Upstream

shadcn/ui's [Dark Mode](https://ui.shadcn.com/docs/dark-mode/vite) page for Vite, from
`apps/v4/content/docs/dark-mode/vite.mdx` at shadcn-ui/ui@8ab2771: its theme provider is
`ColorScheme` here, and its `components/mode-toggle.tsx` the example above.
