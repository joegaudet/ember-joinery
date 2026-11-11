import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { ButtonHarness, ItemHarness } from '@ember-joinery/test-support'
import ItemRtl from 'docs-app/examples/item-rtl'

module('Example | item-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, the actions are on the left', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><ItemRtl /></DirectionProvider>
      </template>,
    )
    const [basic, verified] = ItemHarness.findAll()
    assert.strictEqual(basic!.title, 'عنصر أساسي')
    assert.strictEqual(basic!.find(ButtonHarness).label, 'إجراء')
    const content = basic!.content.getBoundingClientRect()
    const actions = basic!.actions.getBoundingClientRect()
    assert.ok(actions.left < content.left, 'the action is on the left')

    assert.true(verified!.isLink)
    const media = verified!.media.getBoundingClientRect()
    assert.ok(media.left > verified!.actions.getBoundingClientRect().left, 'the badge on the right')
    await a11yAudit()
  })
})
