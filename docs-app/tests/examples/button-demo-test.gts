import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, IconHarness } from '@ember-joinery/test-support'
import ButtonDemo from 'docs-app/examples/button-demo'

module('Example | button-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('an outline button, and an icon button named for screen readers', async function (assert) {
    await render(<template><ButtonDemo /></template>)
    const [text, icon] = ButtonHarness.findAll()

    assert.strictEqual(text!.label, 'Button')
    assert.strictEqual(text!.variant, 'outline')

    assert.strictEqual(icon!.size, 'icon')
    assert.strictEqual(icon!.label, 'Submit', 'named by aria-label')
    assert.strictEqual(icon!.text, '', 'it shows only the icon')
    assert.true(icon!.find(IconHarness).isDecorative, 'the icon itself is hidden')
    await a11yAudit()
  })
})
