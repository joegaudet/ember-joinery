import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { NativeSelect } from '@ember-joinery/ember'
import { NativeSelectHarness } from '@ember-joinery/test-support'
import NativeSelectInvalid from 'docs-app/examples/native-select-invalid'

module('Example | native-select-invalid', function (hooks) {
  setupRenderingTest(hooks)

  test('a select marked invalid, with the destructive border and ring', async function (assert) {
    await render(
      <template>
        <NativeSelectInvalid />
        <NativeSelect @name="valid" aria-label="Valid" as |s|>
          <s.Option @value="">For comparison</s.Option>
        </NativeSelect>
      </template>,
    )
    const [fruit] = NativeSelectHarness.findAll()
    const valid = new NativeSelectHarness('valid')
    assert.true(fruit!.isInvalid, 'aria-invalid="true"')
    assert.false(valid.isInvalid)
    const invalidStyle = getComputedStyle(fruit!.control)
    const validStyle = getComputedStyle(valid.control)
    assert.notStrictEqual(invalidStyle.borderTopColor, validStyle.borderTopColor, 'its border')
    assert.notStrictEqual(invalidStyle.boxShadow, validStyle.boxShadow, 'and its ring')

    await fruit!.select('banana')
    assert.strictEqual(fruit!.value, 'banana', 'it still works')
    await a11yAudit()
  })
})
