import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, LabelHarness, SwitchHarness } from '@ember-joinery/test-support'
import SwitchChoiceCard from 'docs-app/examples/switch-choice-card'

module('Example | switch-choice-card', function (hooks) {
  setupRenderingTest(hooks)

  test('two cards, each a field inside its label; the checked one is tinted', async function (assert) {
    await render(<template><SwitchChoiceCard /></template>)
    const [share, notifications] = FieldHarness.findAll()
    const [shareCard, notificationsCard] = LabelHarness.findAll()

    assert.strictEqual(share!.find(SwitchHarness).label, 'Share across devices')
    assert.false(share!.find(SwitchHarness).isChecked)
    assert.true(notifications!.find(SwitchHarness).isChecked)
    assert.notStrictEqual(
      getComputedStyle(shareCard!.element).backgroundColor,
      getComputedStyle(notificationsCard!.element).backgroundColor,
      'has-data-checked:bg-primary/5',
    )
    await click(share!.part('description'))
    assert.true(share!.find(SwitchHarness).isChecked, 'a press on the card turns it on')
    await a11yAudit()
  })
})
