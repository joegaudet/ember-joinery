import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FormHarness, field } from '@ember-formwright/test-support'
import { ToggleFieldHarness, ToggleGroupFieldHarness } from '@ember-joinery/formwright/test-support'
import FormwrightToggleGroup from 'docs-app/examples/formwright-toggle-group'

class TextForm extends FormHarness {
  static override formName = 'text'
  @field(ToggleGroupFieldHarness) declare size: ToggleGroupFieldHarness
  @field(ToggleGroupFieldHarness) declare marks: ToggleGroupFieldHarness
  @field(ToggleFieldHarness) declare smallCaps: ToggleFieldHarness
}

module('Example | formwright-toggle-group', function (hooks) {
  setupRenderingTest(hooks)

  test('one size, any marks, and small caps on or off', async function (assert) {
    await render(<template><FormwrightToggleGroup /></template>)
    const text = new TextForm()
    assert.strictEqual(text.size.label, 'Size', 'the legend names the group')
    assert.deepEqual(text.size.value, ['md'])
    await text.size.toggle('lg')
    assert.deepEqual(text.size.value, ['lg'], 'one size at a time')

    assert.deepEqual(text.marks.value, ['bold'])
    assert.strictEqual(text.marks.toggleGroup.label('italic'), 'Italic', 'an icon item is named')
    await text.marks.select(['italic', 'underline'])
    assert.deepEqual(text.marks.value, ['italic', 'underline'])

    assert.false(text.smallCaps.value)
    await text.smallCaps.toggle()
    assert.true(text.smallCaps.value)
    await a11yAudit()
  })
})
