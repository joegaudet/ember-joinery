import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BadgeHarness } from '@ember-joinery/test-support'
import BadgeDemo from 'docs-app/examples/badge-demo'

module('Example | badge-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('four badges, one of each main variant', async function (assert) {
    await render(<template><BadgeDemo /></template>)
    const badges = BadgeHarness.findAll()
    assert.deepEqual(
      badges.map(badge => badge.text),
      ['Badge', 'Secondary', 'Destructive', 'Outline'],
    )
    assert.deepEqual(
      badges.map(badge => badge.variant),
      ['default', 'secondary', 'destructive', 'outline'],
    )
    for (const badge of badges) {
      assert.strictEqual(getComputedStyle(badge.element).height, '20px', 'styled: h-5')
    }
    await a11yAudit()
  })
})
