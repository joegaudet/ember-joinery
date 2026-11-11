import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InputGroupHarness, KbdHarness } from '@ember-joinery/test-support'
import KbdInputGroup from 'docs-app/examples/kbd-input-group'

/** The audit, but for Kbd's keys, whose upstream colours fall short of AA (see the Kbd page). */
const BUT_THE_KEYS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="kbd"]']],
}

module('Example | kbd-input-group', function (hooks) {
  setupRenderingTest(hooks)

  test('two keys in an input group’s end addon', async function (assert) {
    await render(<template><KbdInputGroup /></template>)
    const search = new InputGroupHarness()
    const keys = search.findAll(KbdHarness).map(kbd => kbd.label)
    assert.deepEqual(keys, ['⌘', 'K'])
    assert.strictEqual(search.icons.length, 1, 'a search icon at the start')
    assert.deepEqual(search.aligns, ['inline-start', 'inline-end'])
    await a11yAudit(BUT_THE_KEYS)
  })
})
