import { module, test } from 'qunit'
import { setupApplicationTest } from 'docs-app/tests/helpers'
import { currentRouteName, visit } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { exampleNames } from 'docs-app/examples/index'

module('Acceptance | parity route', function (hooks) {
  setupApplicationTest(hooks)

  test('renders one example with no frame and no guide around it', async function (assert) {
    await visit('/parity/introduction')
    assert.strictEqual(currentRouteName(), 'parity')
    assert.dom('[data-parity="introduction"]').exists()
    assert.dom('[data-parity] button').hasText('Bold')
    assert.dom('[data-test-example]').doesNotExist('no example frame')
    assert.dom('.guide-header').doesNotExist('no guide header')
    assert.dom('.guide-sidebar').doesNotExist('no sidebar')
    assert.dom('[data-parity]').hasAttribute('data-align', 'center').hasAttribute('dir', 'ltr')
    assert.dom(document.documentElement).doesNotHaveClass('dark')
    // Parity pages are screenshots, not documents: the audit skips the page-level rules.
    await a11yAudit({ rules: { region: { enabled: false } } })
  })

  test('theme, dir and align set the page up as the comparison asks', async function (assert) {
    await visit('/parity/introduction?theme=dark&dir=rtl&align=start')
    assert.dom(document.documentElement).hasClass('dark')
    assert.dom('[data-parity]').hasAttribute('dir', 'rtl').hasAttribute('data-align', 'start')

    await visit('/getting-started/introduction.md')
    assert.dom(document.documentElement).doesNotHaveClass('dark', 'leaving the route undoes it')
  })

  test('an unknown example says so', async function (assert) {
    await visit('/parity/no-such-example')
    assert.dom('[data-parity-missing="no-such-example"]').exists()
    assert.dom('[data-parity]').doesNotExist()
  })

  test('every example renders on its own', async function (assert) {
    for (const name of exampleNames()) {
      await visit(`/parity/${name}`)
      assert.dom(`[data-parity="${name}"]`).exists(name)
    }
  })
})
