import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { EmptyHarness, InputGroupHarness, KbdHarness } from '@ember-joinery/test-support'
import EmptyInputGroup from 'docs-app/examples/empty-input-group'

/** The audit, but for Kbd's keys, whose upstream colours fall short of AA (see the Kbd page). */
const BUT_THE_KEYS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="kbd"]']],
}

module('Example | empty-input-group', function (hooks) {
  setupRenderingTest(hooks)

  test('a 404 page with a search field in its content', async function (assert) {
    await render(<template><EmptyInputGroup /></template>)
    const empty = new EmptyHarness()
    assert.strictEqual(empty.title, '404 - Not Found')
    const search = empty.find(InputGroupHarness)
    assert.strictEqual(search.placeholder, 'Try searching for pages...')
    assert.strictEqual(search.find(KbdHarness).label, '/')
    assert.dom('a[href="#"]').hasText('Contact support')
    await search.fillIn('pricing')
    assert.strictEqual(search.value, 'pricing')
    await a11yAudit(BUT_THE_KEYS)
  })
})
