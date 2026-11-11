import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CheckboxHarness } from '@ember-joinery/test-support'
import CheckboxHeadless from 'docs-app/examples/checkbox-headless'

module('Example | checkbox-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('a checkbox with styles of its own, whose mark shows while checked', async function (assert) {
    await render(<template><CheckboxHeadless /></template>)
    const terms = new CheckboxHarness()

    assert.strictEqual(terms.label, 'Accept terms and conditions')
    assert.dom(terms.element).doesNotHaveAttribute('data-slot', 'no styled part')
    assert.strictEqual(terms.indicator, null)
    assert.strictEqual(getComputedStyle(terms.element).width, '20px', 'its own size-5')

    await terms.toggle()
    assert.true(terms.isChecked)
    assert.dom(terms.indicator).hasText('✓')
    await a11yAudit()
  })
})
