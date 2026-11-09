import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { setupColorScheme } from '@ember-joinery/test-support'
import ColorSchemeModeToggle from 'docs-app/examples/color-scheme-mode-toggle'

module('Example | color-scheme-mode-toggle', function (hooks) {
  setupRenderingTest(hooks)
  // Each test starts with nothing saved, on a system that prefers light.
  const system = setupColorScheme(hooks, { system: 'light' })

  test('it follows the system until you choose, and saves the choice', async function (assert) {
    const html = document.documentElement
    await render(<template><ColorSchemeModeToggle /></template>)
    assert.dom('p').hasText('The page is light.')
    assert.dom('button:nth-of-type(3)').hasAria('pressed', 'true', 'System is the default')

    system.setSystem('dark')
    await settled()
    assert.dom('p').hasText('The page is dark.', 'the OS switched to dark mode')
    assert.dom(html).hasClass('dark')

    await click('button:nth-of-type(1)')
    assert.dom('p').hasText('The page is light.')
    assert.dom('button:nth-of-type(1)').hasAria('pressed', 'true')
    assert.dom(html).doesNotHaveClass('dark')
    assert.strictEqual(system.stored, 'light', 'saved for the next visit')
    await a11yAudit()
  })
})
