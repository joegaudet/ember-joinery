import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonGroupHarness, FieldHarness, InputHarness } from '@ember-joinery/test-support'
import InputButtonGroup from 'docs-app/examples/input-button-group'

module('Example | input-button-group', function (hooks) {
  setupRenderingTest(hooks)

  test('a labelled search input joined to its Search button', async function (assert) {
    await render(<template><InputButtonGroup /></template>)
    const field = new FieldHarness()
    const group = field.find(ButtonGroupHarness)
    const input = group.find(InputHarness)
    const [search] = group.buttons
    assert.strictEqual(input.label, 'Search', 'the FieldLabel names the input')
    assert.strictEqual(input.placeholder, 'Type to search...')
    assert.strictEqual(search!.label, 'Search')
    assert.strictEqual(search!.variant, 'outline')

    const inputStyle = getComputedStyle(input.element)
    const buttonStyle = getComputedStyle(search!.element)
    assert.strictEqual(inputStyle.borderTopRightRadius, '0px', 'joined: the input’s end is square')
    assert.strictEqual(buttonStyle.borderTopLeftRadius, '0px', 'and the button’s start')
    assert.strictEqual(
      Math.round(input.element.getBoundingClientRect().right),
      Math.round(search!.element.getBoundingClientRect().left),
      'side by side',
    )

    await input.fillIn('avatars')
    assert.strictEqual(input.value, 'avatars')
    await a11yAudit()
  })
})
