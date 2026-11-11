import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, InputGroupHarness, TooltipHarness } from '@ember-joinery/test-support'
import ButtonGroupInputGroup from 'docs-app/examples/button-group-input-group'

module('Example | button-group-input-group', function (hooks) {
  setupRenderingTest(hooks)

  test('voice mode: the addon button toggles, and the input waits', async function (assert) {
    await render(<template><ButtonGroupInputGroup /></template>)
    const message = new InputGroupHarness()
    const voice = message.find(ButtonHarness)
    const tooltip = new TooltipHarness()
    assert.strictEqual(tooltip.trigger, voice.element)
    assert.strictEqual(message.placeholder, 'Send a message...')
    assert.false(voice.isPressed)
    assert.true(
      parseFloat(getComputedStyle(message.element).borderTopLeftRadius) > 100,
      "the group's --radius makes it a pill",
    )

    await tooltip.hover()
    assert.strictEqual(tooltip.text, 'Voice Mode')
    await a11yAudit()

    await voice.click()
    assert.true(voice.isPressed)
    assert.true(message.isDisabled)
    assert.strictEqual(message.placeholder, 'Record and send audio...')
    await a11yAudit()
  })
})
