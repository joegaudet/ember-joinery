import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { SliderFieldHarness } from '@ember-joinery/formwright/test-support'
import FormwrightSlider from 'docs-app/examples/formwright-slider'

class FiltersForm extends FormHarness {
  static override formName = 'filters'
  @field(SliderFieldHarness) declare volume: SliderFieldHarness
  @field(SliderFieldHarness) declare price: SliderFieldHarness
}

module('Example | formwright-slider', function (hooks) {
  setupRenderingTest(hooks)

  test('a slider stores a number, and a range one number for each thumb', async function (assert) {
    await render(<template><FormwrightSlider /></template>)
    const filters = new FiltersForm()
    assert.deepEqual(filters.volume.value, [50])
    assert.deepEqual(filters.volume.slider.labels, ['Volume'])
    assert.strictEqual(filters.volume.hint, 'Turn it up in steps of ten.')
    const hintOf = (field: SliderFieldHarness): string =>
      field.element.querySelector('[data-test-fw-hint]')!.id
    for (const thumb of filters.volume.slider.thumbs) {
      assert
        .dom(thumb)
        .hasAttribute('aria-describedby', hintOf(filters.volume), 'its hint describes it')
    }
    await filters.volume.press('ArrowRight')
    assert.deepEqual(filters.volume.value, [60], 'in steps of ten')
    assert.true(filters.volume.isDirty)

    assert.deepEqual(filters.price.value, [200, 800])
    assert.deepEqual(filters.price.slider.labels, ['Price, Minimum', 'Price, Maximum'])
    for (const thumb of filters.price.slider.thumbs) {
      assert.dom(thumb).hasAttribute('aria-describedby', hintOf(filters.price))
    }
    await filters.price.press('End', 1)
    assert.deepEqual(filters.price.value, [200, 1000])
    await a11yAudit()
  })
})
