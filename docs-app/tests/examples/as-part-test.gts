import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import AsPart from 'docs-app/examples/as-part'

module('Example | as-part', function (hooks) {
  setupRenderingTest(hooks)

  test('the part component and the part modifier are both the trigger', async function (assert) {
    await render(<template><AsPart /></template>)
    assert.dom('button').hasAria('expanded', 'false').hasAttribute('data-state', 'closed')
    assert.dom('a').hasAria('expanded', 'false', 'the link got the same attributes')
    assert.dom('p').isNotVisible()

    await click('a')
    assert.dom('p').isVisible('the link opened it')
    assert.dom('button').hasAria('expanded', 'true')
    assert.dom('a').hasAria('expanded', 'true').hasAttribute('data-state', 'open')

    await click('button')
    assert.dom('p').isNotVisible('and the button closed it')
    await a11yAudit()
  })
})
