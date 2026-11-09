import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BadgeHarness, SpinnerHarness } from '@ember-joinery/test-support'
import SpinnerBadge from 'docs-app/examples/spinner-badge'

module('Example | spinner-badge', function (hooks) {
  setupRenderingTest(hooks)

  test('badges that are loading, each with a spinner before its label', async function (assert) {
    await render(<template><SpinnerBadge /></template>)
    const badges = BadgeHarness.findAll()
    assert.deepEqual(
      badges.map(badge => [badge.text, badge.variant]),
      [
        ['Syncing', 'default'],
        ['Updating', 'secondary'],
        ['Processing', 'outline'],
      ],
    )
    for (const badge of badges) {
      const spinner = badge.find(SpinnerHarness)
      assert.strictEqual(spinner.label, 'Loading')
      const box = badge.element.getBoundingClientRect()
      assert.ok(
        spinner.element.getBoundingClientRect().left < box.left + box.width / 2,
        `${badge.text}: at the inline start`,
      )
      // The example's [--radius:1.2rem]: rounded-4xl is --radius × 2.6, more than half the
      // badge's 20px, so it stays a pill.
      assert.strictEqual(getComputedStyle(badge.element).borderTopLeftRadius, '49.92px')
    }
    await a11yAudit()
  })
})
