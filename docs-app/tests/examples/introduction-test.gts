import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import Introduction from 'docs-app/examples/introduction'

module('Example | introduction', function (hooks) {
  setupRenderingTest(hooks)

  test('pressing the toggle turns it on, and pressing it again turns it off', async function (assert) {
    await render(<template><Introduction /></template>)

    // State is read through ARIA, the way a screen reader reads it.
    assert.dom('button').hasText('Bold').hasAria('pressed', 'false')

    await click('button')
    assert.dom('button').hasAria('pressed', 'true').hasAttribute('data-state', 'on')

    await click('button')
    assert.dom('button').hasAria('pressed', 'false').hasAttribute('data-state', 'off')

    await a11yAudit()
  })
})
