import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, InputGroupHarness } from '@ember-joinery/test-support'
import InputGroupCustom from 'docs-app/examples/input-group-custom'

module('Example | input-group-custom', function (hooks) {
  setupRenderingTest(hooks)

  test('a textarea of its own, which grows, marked as the group’s control', async function (assert) {
    await render(<template><InputGroupCustom /></template>)
    const group = new InputGroupHarness()
    assert
      .dom(group.control)
      .hasTagName('textarea')
      .hasAttribute('data-slot', 'input-group-control')
    assert.strictEqual(group.placeholder, 'Autoresize textarea...')
    const empty = group.control.getBoundingClientRect().height
    await group.fillIn('One\nTwo\nThree\nFour\nFive')
    assert.ok(group.control.getBoundingClientRect().height > empty, 'field-sizing-content')

    await group.focus()
    assert.ok(
      getComputedStyle(group.element).boxShadow.includes(' 3px'),
      'its focus rings the group',
    )
    assert.strictEqual(new ButtonHarness().label, 'Submit')
    await a11yAudit()
  })
})
