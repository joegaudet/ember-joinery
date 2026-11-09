import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ButtonHarness,
  FieldHarness,
  FieldSetHarness,
  InputHarness,
} from '@ember-joinery/test-support'
import FieldResponsive from 'docs-app/examples/field-responsive'

module('Example | field-responsive', function (hooks) {
  setupRenderingTest(hooks)

  test('the label and its input side by side in a wide group, stacked in a narrow one', async function (assert) {
    await render(
      <template>
        <div data-test-width style="width: 512px"><FieldResponsive /></div>
      </template>,
    )
    const profile = new FieldSetHarness()
    const [name, actions] = FieldHarness.findAll()

    assert.strictEqual(profile.legend, 'Profile')
    assert.strictEqual(profile.description, 'Fill in your profile information.')
    assert.strictEqual(name!.label, 'Name')
    assert.strictEqual(name!.description, 'Provide your full name for identification')
    assert.true(name!.find(InputHarness).isRequired)
    assert.deepEqual(
      actions!.findAll(ButtonHarness).map(button => button.text),
      ['Submit', 'Cancel'],
    )
    assert.strictEqual(getComputedStyle(name!.element).flexDirection, 'row', 'wide: side by side')

    document.querySelector<HTMLElement>('[data-test-width]')!.style.width = '320px'
    await new Promise(requestAnimationFrame)
    assert.strictEqual(getComputedStyle(name!.element).flexDirection, 'column', 'narrow: stacked')
    await a11yAudit()
  })
})
