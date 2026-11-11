import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness } from '@ember-joinery/test-support'
import ButtonRounded from 'docs-app/examples/button-rounded'

module('Example | button-rounded', function (hooks) {
  setupRenderingTest(hooks)

  test('a class rounds it fully, over the style', async function (assert) {
    await render(<template><ButtonRounded /></template>)
    const button = new ButtonHarness()
    assert.dom(button.element).hasClass('rounded-full')
    assert.strictEqual(button.label, 'Submit')
    const radius = Number.parseFloat(getComputedStyle(button.element).borderTopLeftRadius)
    assert.ok(radius > 1000, `rounded-full wins over the style's radius (${radius}px)`)
    await a11yAudit()
  })
})
