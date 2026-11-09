import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import PresenceFade from 'docs-app/examples/presence-fade'

module('Example | presence-fade', function (hooks) {
  setupRenderingTest(hooks)

  test('the panel animates out, then goes', async function (assert) {
    await render(<template><PresenceFade /></template>)
    assert.dom('.presence-panel').hasAttribute('data-state', 'open')

    // click() waits until the page settles, and Presence holds that until the exit ends.
    await click('button')
    assert.dom('.presence-panel').doesNotExist()
    assert.dom('button').hasText('Show').hasAria('expanded', 'false')

    await click('button')
    assert.dom('.presence-panel').exists()
    await a11yAudit()
  })
})
