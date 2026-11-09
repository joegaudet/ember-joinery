import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BadgeHarness, IconHarness } from '@ember-joinery/test-support'
import BadgeIcon from 'docs-app/examples/badge-icon'

module('Example | badge-icon', function (hooks) {
  setupRenderingTest(hooks)

  test('an icon before one label and after the other, with the narrower padding beside it', async function (assert) {
    await render(<template><BadgeIcon /></template>)
    const [verified, bookmark] = BadgeHarness.findAll()
    assert.strictEqual(verified!.text, 'Verified')
    assert.strictEqual(bookmark!.text, 'Bookmark')

    for (const [badge, atTheStart] of [
      [verified!, true],
      [bookmark!, false],
    ] as const) {
      const icon = badge.find(IconHarness)
      assert.true(icon.isDecorative, 'the icon is hidden from assistive technology')
      assert.strictEqual(getComputedStyle(icon.element).width, '12px', 'size-3')
      const box = badge.element.getBoundingClientRect()
      const left = icon.element.getBoundingClientRect().left < box.left + box.width / 2
      assert.strictEqual(left, atTheStart, `${badge.text}: the icon's side`)
    }
    assert.strictEqual(getComputedStyle(verified!.element).paddingLeft, '6px')
    assert.strictEqual(getComputedStyle(bookmark!.element).paddingRight, '6px')
    await a11yAudit()
  })
})
