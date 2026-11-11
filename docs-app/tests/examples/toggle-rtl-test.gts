import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ToggleHarness, IconHarness } from '@ember-joinery/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import ToggleRtl from 'docs-app/examples/toggle-rtl'

module('Example | toggle-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, the icon leads on the right', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl"><ToggleRtl /></DirectionProvider>
      </template>,
    )
    const toggle = new ToggleHarness()
    assert.strictEqual(toggle.text, 'إشارة مرجعية')
    const icon = toggle.find(IconHarness).element.getBoundingClientRect()
    const box = toggle.element.getBoundingClientRect()
    assert.true(icon.left > box.left + box.width / 2, 'the icon is on the right')
    await toggle.toggle()
    assert.true(toggle.isPressed)
    await a11yAudit()
  })
})
