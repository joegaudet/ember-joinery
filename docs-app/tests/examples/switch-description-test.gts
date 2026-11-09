import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, LabelHarness, SwitchHarness } from '@ember-joinery/test-support'
import SwitchDescription from 'docs-app/examples/switch-description'

module('Example | switch-description', function (hooks) {
  setupRenderingTest(hooks)

  test('a label and its description, then the switch', async function (assert) {
    await render(<template><SwitchDescription /></template>)
    const field = new FieldHarness()
    const share = field.find(SwitchHarness)

    assert.strictEqual(share.label, 'Share across devices')
    assert.strictEqual(
      field.description,
      'Focus is shared across devices, and turns off when you leave the app.',
    )
    assert.true(
      share.element.getBoundingClientRect().left > field.content!.getBoundingClientRect().right,
      'the switch after its text',
    )
    await field.find(LabelHarness).click()
    assert.true(share.isChecked)
    await a11yAudit()
  })
})
