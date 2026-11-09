import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import ServiceCounter from 'docs-app/examples/service-counter'

module('Example | service-counter', function (hooks) {
  setupRenderingTest(hooks)

  test('both buttons add to the one cart', async function (assert) {
    await render(<template><ServiceCounter /></template>)
    assert.dom('output').hasText('0')
    await click('button:nth-of-type(1)')
    await click('button:nth-of-type(2)')
    assert.dom('output').hasText('2')
    await a11yAudit()
  })

  test('each test gets its own cart', async function (assert) {
    await render(<template><ServiceCounter /></template>)
    assert.dom('output').hasText('0', 'nothing carried over from the last test')
  })
})
