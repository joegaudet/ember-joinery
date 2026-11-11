import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { BadgeHarness, IconHarness } from '@ember-joinery/test-support'
import BadgeRtl from 'docs-app/examples/badge-rtl'

module('Example | badge-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, the inline start is the right', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><BadgeRtl /></DirectionProvider>
      </template>,
    )
    const badges = BadgeHarness.findAll()
    assert.deepEqual(
      badges.map(badge => badge.text),
      ['شارة', 'ثانوي', 'مدمر', 'مخطط', 'متحقق', 'إشارة مرجعية'],
    )
    const [first, second] = badges
    assert.ok(
      first!.element.getBoundingClientRect().left > second!.element.getBoundingClientRect().left,
      'the first badge is on the right',
    )
    const verified = badges[4]!
    const bookmark = badges[5]!
    for (const [badge, onTheRight] of [
      [verified, true],
      [bookmark, false],
    ] as const) {
      const box = badge.element.getBoundingClientRect()
      const icon = badge.find(IconHarness).element.getBoundingClientRect()
      assert.strictEqual(
        icon.left > box.left + box.width / 2,
        onTheRight,
        `${badge.text}: its icon`,
      )
    }
    assert.strictEqual(
      getComputedStyle(verified.element).paddingRight,
      '6px',
      'ps-1.5 is the right',
    )
    assert.strictEqual(getComputedStyle(bookmark.element).paddingLeft, '6px', 'pe-1.5 is the left')
    await a11yAudit()
  })
})
