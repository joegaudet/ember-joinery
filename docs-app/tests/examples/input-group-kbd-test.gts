import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InputGroupHarness, KbdHarness } from '@ember-joinery/test-support'
import InputGroupKbd from 'docs-app/examples/input-group-kbd'

/** The audit, but for Kbd's keys, whose upstream colours fall short of AA (see the Kbd page). */
const BUT_THE_KEYS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="kbd"]']],
}

module('Example | input-group-kbd', function (hooks) {
  setupRenderingTest(hooks)

  test('a search field with its shortcut at the end', async function (assert) {
    await render(<template><InputGroupKbd /></template>)
    const search = new InputGroupHarness()
    const shortcut = search.find(KbdHarness)
    assert.strictEqual(shortcut.label, '⌘K')
    assert.strictEqual(search.addon('inline-end'), shortcut.element.parentElement)
    assert.strictEqual(
      getComputedStyle(search.addon('inline-end')).marginRight,
      '-2.4px',
      'has-[>kbd]:me-[-0.15rem]: the key sits closer to the edge',
    )
    await a11yAudit(BUT_THE_KEYS)
  })
})
