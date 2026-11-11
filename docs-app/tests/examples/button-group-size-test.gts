import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonGroupHarness } from '@ember-joinery/test-support'
import ButtonGroupSize from 'docs-app/examples/button-group-size'

module('Example | button-group-size', function (hooks) {
  setupRenderingTest(hooks)

  test('three groups, sized by their buttons', async function (assert) {
    await render(<template><ButtonGroupSize /></template>)
    const groups = ButtonGroupHarness.findAll()
    assert.strictEqual(groups.length, 3)
    assert.deepEqual(
      groups.map(group => group.buttons.map(button => button.size)),
      [
        ['sm', 'sm', 'sm', 'icon-sm'],
        ['default', 'default', 'default', 'icon'],
        ['lg', 'lg', 'lg', 'icon-lg'],
      ],
    )
    assert.deepEqual(
      groups.map(group => getComputedStyle(group.element).height),
      ['28px', '32px', '36px'],
    )
    assert.deepEqual(
      groups.map(group => group.buttons.at(-1)!.label),
      ['Add', 'Add', 'Add'],
    )
    await a11yAudit()
  })
})
