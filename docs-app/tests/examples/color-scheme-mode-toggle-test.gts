import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, setupColorScheme } from '@ember-joinery/test-support'
import ColorSchemeModeToggle from 'docs-app/examples/color-scheme-mode-toggle'

/** The example's mode toggle: one pressed option, and a line saying what the page is. */
class ModeToggleHarness extends Harness {
  static component = 'mode-toggle'

  /** The option that is pressed: `light`, `dark` or `system`. */
  get chosen() {
    const option = this.parts('option').find(
      button => button.getAttribute('aria-pressed') === 'true',
    )
    return option?.getAttribute('data-test-jn-value')
  }

  get status() {
    return this.part('status').textContent!.trim()
  }

  async choose(preference: 'light' | 'dark' | 'system') {
    await click(this.part('option', preference))
  }
}

module('Example | color-scheme-mode-toggle', function (hooks) {
  setupRenderingTest(hooks)
  // Each test starts with nothing saved, on a system that prefers light.
  const system = setupColorScheme(hooks, { system: 'light' })

  test('it follows the system until you choose, and saves the choice', async function (assert) {
    const html = document.documentElement
    await render(<template><ColorSchemeModeToggle /></template>)
    const toggle = new ModeToggleHarness()
    assert.strictEqual(toggle.status, 'The page is light.')
    assert.strictEqual(toggle.chosen, 'system', 'System is the default')

    system.setSystem('dark')
    await settled()
    assert.strictEqual(toggle.status, 'The page is dark.', 'the OS switched to dark mode')
    assert.dom(html).hasClass('dark')

    await toggle.choose('light')
    assert.strictEqual(toggle.chosen, 'light')
    assert.strictEqual(toggle.status, 'The page is light.')
    assert.dom(html).doesNotHaveClass('dark')
    assert.strictEqual(system.stored, 'light', 'saved for the next visit')
    await a11yAudit()
  })
})
