import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { destroy } from '@ember/destroyable'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  COLOR_SCHEME_STORAGE_KEY,
  ColorScheme,
  colorScheme,
  colorSchemeScript,
  getColorScheme,
  prefers,
  removeColorScheme,
  setColorScheme,
} from '@ember-joinery/primitives/color-scheme'
import { service } from '@ember-joinery/primitives/service'
import { setupColorScheme } from '@ember-joinery/test-support'

const html = document.documentElement

/** A mode toggle, as shadcn's dark-mode pages build one. */
const ModeToggle = <template>
  {{#let (service ColorScheme) as |scheme|}}
    <output>{{scheme.preference}} / {{scheme.current}}</output>
    <button id="light" type="button" {{on "click" (fn scheme.set "light")}}>Light</button>
    <button id="dark" type="button" {{on "click" (fn scheme.set "dark")}}>Dark</button>
    <button id="system" type="button" {{on "click" (fn scheme.set "system")}}>System</button>
    <button id="toggle" type="button" {{on "click" scheme.toggle}}>Toggle</button>
  {{/let}}
</template>

module('Integration | primitives | color-scheme', function (hooks) {
  setupRenderingTest(hooks)
  const system = setupColorScheme(hooks, { system: 'light' })

  test('it follows the system until the user chooses', async function (assert) {
    await render(<template><ModeToggle /></template>)
    assert.dom('output').hasText('system / light')
    assert.dom(html).doesNotHaveClass('dark')
    assert.strictEqual(html.style.colorScheme, 'light')

    system.setSystem('dark')
    await settled()
    assert.dom('output').hasText('system / dark', 'the OS switched to dark mode')
    assert.dom(html).hasClass('dark')
    assert.strictEqual(html.style.colorScheme, 'dark')
    assert.strictEqual(system.stored, null, 'following the system saves nothing')
    await a11yAudit()
  })

  test('a choice is applied, saved, and wins over the system', async function (assert) {
    await render(<template><ModeToggle /></template>)
    await click('#dark')
    assert.dom('output').hasText('dark / dark')
    assert.dom(html).hasClass('dark')
    assert.strictEqual(system.stored, 'dark')

    system.setSystem('light')
    await settled()
    assert.dom(html).hasClass('dark', 'the system no longer decides')

    await click('#toggle')
    assert.dom('output').hasText('light / light', 'toggle goes to the other one')
    assert.dom(html).doesNotHaveClass('dark')

    await click('#system')
    assert.dom('output').hasText('system / light')
    assert.strictEqual(system.stored, 'system', 'choosing the system is saved too')
    await a11yAudit()
  })

  test('the saved choice is read at the start', async function (assert) {
    localStorage.setItem(COLOR_SCHEME_STORAGE_KEY, 'dark')
    await render(<template><ModeToggle /></template>)
    assert.dom('output').hasText('dark / dark')
    assert.dom(html).hasClass('dark')
  })

  test('an unknown saved value is ignored', async function (assert) {
    localStorage.setItem(COLOR_SCHEME_STORAGE_KEY, 'sepia')
    await render(<template><ModeToggle /></template>)
    assert.dom('output').hasText('system / light')
  })

  test('a choice made in another tab applies here', async function (assert) {
    await render(<template><ModeToggle /></template>)
    system.fromAnotherTab('dark')
    await settled()
    assert.dom('output').hasText('dark / dark')
    assert.dom(html).hasClass('dark')

    system.fromAnotherTab(null)
    await settled()
    assert.dom('output').hasText('system / light', 'cleared there, it follows the system again')
  })

  test('one instance per app, from JavaScript or a template', async function (assert) {
    await render(<template><ModeToggle /></template>)
    const scheme = colorScheme(this.owner)
    assert.strictEqual(scheme, service(this.owner, ColorScheme))
    scheme.set('dark')
    await settled()
    assert.dom('output').hasText('dark / dark', 'the template sees the same instance')
    assert.true(scheme.isDark)
    assert.false(scheme.isLight)
  })

  test('onChange hears each change of the scheme in effect', async function (assert) {
    const scheme = colorScheme(this.owner)
    const heard: string[] = []
    const stop = scheme.onChange((current, preference) => heard.push(`${current}:${preference}`))
    scheme.set('dark')
    scheme.set('dark')
    scheme.set('system')
    system.setSystem('dark')
    stop()
    scheme.set('light')
    assert.deepEqual(heard, ['dark:dark', 'light:system', 'dark:system'])
  })

  test('configure() sets the storage key, classes and element', async function (assert) {
    const element = document.createElement('div')
    document.body.append(element)
    localStorage.setItem('my-theme', 'dark')
    try {
      const scheme = colorScheme(this.owner).configure({
        storageKey: 'my-theme',
        element,
        darkClass: 'theme-dark',
        lightClass: 'theme-light',
      })
      assert.strictEqual(scheme.current, 'dark', 'the new key was read')
      assert.dom(element).hasClass('theme-dark').doesNotHaveClass('theme-light')
      assert.strictEqual(element.style.colorScheme, 'dark')
      assert.dom(html).doesNotHaveClass('dark', '<html> was left alone')
      assert.strictEqual(html.style.colorScheme, '', '<html> was put back')

      scheme.set('light')
      assert.dom(element).hasClass('theme-light').doesNotHaveClass('theme-dark')
      assert.strictEqual(localStorage.getItem('my-theme'), 'light')
      assert.strictEqual(system.stored, null, 'nothing under the default key')
    } finally {
      localStorage.removeItem('my-theme')
      element.remove()
    }
  })

  test('with storageKey null, nothing is saved', async function (assert) {
    const scheme = colorScheme(this.owner).configure({ storageKey: null })
    scheme.set('dark')
    assert.strictEqual(system.stored, null)
    assert.dom(html).hasClass('dark')
  })

  test('disableTransitionOnChange turns transitions off for the change', async function (assert) {
    const scheme = colorScheme(this.owner).configure({ disableTransitionOnChange: true })
    const before = document.head.querySelectorAll('style').length
    scheme.set('dark')
    const added = [...document.head.querySelectorAll('style')].at(-1)!
    assert.strictEqual(document.head.querySelectorAll('style').length, before + 1)
    assert.true(added.textContent!.includes('transition:none!important'))
    await settled()
    assert.strictEqual(document.head.querySelectorAll('style').length, before, 'then removed')
  })

  test('<html> is put back when the app is destroyed', async function (assert) {
    html.classList.add('dark')
    try {
      const scheme = colorScheme(this.owner)
      assert.strictEqual(scheme.current, 'light')
      assert.dom(html).doesNotHaveClass('dark', 'it applied the light scheme')
      destroy(scheme)
      await settled()
      assert.dom(html).hasClass('dark', 'the class it found is back')
      assert.strictEqual(html.style.colorScheme, '')
    } finally {
      html.classList.remove('dark')
    }
  })

  test('colorSchemeScript() applies the saved scheme before the app runs', function (assert) {
    localStorage.setItem(COLOR_SCHEME_STORAGE_KEY, 'dark')
    try {
      new Function(colorSchemeScript())()
      assert.dom(html).hasClass('dark')
      assert.strictEqual(html.style.colorScheme, 'dark')

      localStorage.setItem(COLOR_SCHEME_STORAGE_KEY, 'system')
      new Function(colorSchemeScript())()
      assert.dom(html).doesNotHaveClass('dark', 'system resolves to the light system')

      localStorage.removeItem(COLOR_SCHEME_STORAGE_KEY)
      new Function(colorSchemeScript({ defaultPreference: 'dark', darkClass: 'night' }))()
      assert.dom(html).hasClass('night', 'the default and class options are used')
    } finally {
      html.classList.remove('dark', 'night')
      html.style.removeProperty('color-scheme')
    }
  })

  test('the helpers read and write color-scheme directly', function (assert) {
    assert.false(prefers.dark())
    assert.true(prefers.light())
    system.setSystem('dark')
    assert.true(prefers.dark())

    const element = document.createElement('div')
    setColorScheme(element, 'dark')
    assert.strictEqual(getColorScheme(element), 'dark')
    removeColorScheme(element)
    assert.strictEqual(getColorScheme(element), '')
  })
})
