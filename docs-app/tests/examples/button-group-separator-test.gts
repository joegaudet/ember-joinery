import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonGroupHarness } from '@ember-joinery/test-support'
import ButtonGroupSeparator from 'docs-app/examples/button-group-separator'

module('Example | button-group-separator', function (hooks) {
  setupRenderingTest(hooks)

  test('copy and paste, divided by a line', async function (assert) {
    await render(<template><ButtonGroupSeparator /></template>)
    const group = new ButtonGroupHarness()
    assert.deepEqual(
      group.buttons.map(button => [button.label, button.variant, button.size]),
      [
        ['Copy', 'secondary', 'sm'],
        ['Paste', 'secondary', 'sm'],
      ],
    )
    const [line] = group.separators
    assert.dom(line).hasAttribute('data-orientation', 'vertical').hasAttribute('role', 'none')
    assert.strictEqual(getComputedStyle(line!).width, '1px')
    await a11yAudit()
  })
})
