import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonGroupHarness } from '@ember-joinery/test-support'
import ButtonGroupOrientation from 'docs-app/examples/button-group-orientation'

module('Example | button-group-orientation', function (hooks) {
  setupRenderingTest(hooks)

  test('two icon buttons, stacked, in a named group', async function (assert) {
    await render(<template><ButtonGroupOrientation /></template>)
    const group = new ButtonGroupHarness()
    assert.strictEqual(group.orientation, 'vertical')
    assert.strictEqual(group.label, 'Media controls')
    assert.strictEqual(getComputedStyle(group.element).flexDirection, 'column')
    const [plus, minus] = group.buttons
    assert.strictEqual(plus!.label, 'Increase')
    assert.strictEqual(minus!.label, 'Decrease')
    assert.ok(
      minus!.element.getBoundingClientRect().top > plus!.element.getBoundingClientRect().top,
      'one above the other',
    )
    assert.strictEqual(getComputedStyle(plus!.element).borderBottomLeftRadius, '0px')
    await a11yAudit()
  })
})
