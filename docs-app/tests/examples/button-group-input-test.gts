import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonGroupHarness, IconHarness, InputHarness } from '@ember-joinery/test-support'
import ButtonGroupInput from 'docs-app/examples/button-group-input'

module('Example | button-group-input', function (hooks) {
  setupRenderingTest(hooks)

  test('a search input joined to its search button', async function (assert) {
    await render(<template><ButtonGroupInput /></template>)
    const group = new ButtonGroupHarness()
    const input = group.find(InputHarness)
    const [search] = group.buttons
    assert.strictEqual(group.buttons.length, 1)
    assert.strictEqual(input.placeholder, 'Search...')
    assert.strictEqual(input.label, 'Search...', 'the placeholder names it')
    assert.strictEqual(search!.label, 'Search')
    assert.strictEqual(search!.variant, 'outline')
    assert.true(search!.find(IconHarness).isDecorative)

    const field = getComputedStyle(input.element)
    const button = getComputedStyle(search!.element)
    assert.strictEqual(field.flexGrow, '1', 'the input takes the room: [&>input]:flex-1')
    assert.strictEqual(field.borderTopRightRadius, '0px', 'joined: the input’s end is square')
    assert.strictEqual(button.borderTopLeftRadius, '0px', 'and the button’s start')
    assert.strictEqual(button.borderLeftWidth, '0px', 'one border between them')
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
