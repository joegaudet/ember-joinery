import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, SliderHarness } from '@ember-joinery/test-support'
import FieldSlider from 'docs-app/examples/field-slider'

module('Example | field-slider', function (hooks) {
  setupRenderingTest(hooks)

  test('a titled price range, whose description follows its two thumbs', async function (assert) {
    await render(<template><FieldSlider /></template>)
    const field = new FieldHarness()
    const price = field.find(SliderHarness)

    assert.strictEqual(field.title, 'Price Range')
    assert.strictEqual(field.description, 'Set your budget range ($200 - 800).')
    assert.deepEqual(price.value, [200, 800])
    assert.strictEqual(price.max, 1000)
    assert.deepEqual(price.labels, ['Minimum', 'Maximum'])
    assert.dom(price.element).hasAttribute('role', 'group').hasAria('label', 'Price Range')

    await price.focus(0)
    await price.press('ArrowRight')
    assert.deepEqual(price.value, [210, 800], 'in steps of 10')
    assert.strictEqual(field.description, 'Set your budget range ($210 - 800).')

    await price.press('End', { thumb: 1 })
    assert.deepEqual(price.value, [210, 1000])
    assert.strictEqual(field.description, 'Set your budget range ($210 - 1000).')
    await a11yAudit()
  })
})
