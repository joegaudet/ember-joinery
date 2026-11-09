import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BadgeHarness } from '@ember-joinery/test-support'
import BadgeVariants from 'docs-app/examples/badge-variants'

module('Example | badge-variants', function (hooks) {
  setupRenderingTest(hooks)

  test('one badge for each variant @variant names', async function (assert) {
    await render(<template><BadgeVariants /></template>)
    const badges = BadgeHarness.findAll()
    assert.deepEqual(
      badges.map(badge => [badge.text, badge.variant]),
      [
        ['Default', 'default'],
        ['Secondary', 'secondary'],
        ['Destructive', 'destructive'],
        ['Outline', 'outline'],
        ['Ghost', 'ghost'],
      ],
    )
    const [first, , , , ghost] = badges
    assert.notStrictEqual(
      getComputedStyle(first!.element).backgroundColor,
      getComputedStyle(ghost!.element).backgroundColor,
      'the default is filled, the ghost is not',
    )
    await a11yAudit()
  })
})
