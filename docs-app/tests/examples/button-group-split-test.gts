import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonGroupHarness, IconHarness } from '@ember-joinery/test-support'
import ButtonGroupSplit from 'docs-app/examples/button-group-split'

module('Example | button-group-split', function (hooks) {
  setupRenderingTest(hooks)

  test('a button, a separator and an icon button: a split button', async function (assert) {
    await render(<template><ButtonGroupSplit /></template>)
    const group = new ButtonGroupHarness()
    const [main, more] = group.buttons
    assert.strictEqual(main!.label, 'Button')
    assert.strictEqual(more!.label, 'Add')
    assert.strictEqual(more!.size, 'icon')
    assert.true(more!.find(IconHarness).isDecorative)
    assert.strictEqual(group.separators.length, 1)
    assert.strictEqual(getComputedStyle(main!.element).borderTopRightRadius, '0px', 'joined')
    assert.strictEqual(getComputedStyle(more!.element).borderTopLeftRadius, '0px')
    await a11yAudit()
  })
})
