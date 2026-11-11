import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { IconHarness, NativeSelectHarness } from '@ember-joinery/test-support'
import NativeSelectIcon from 'docs-app/examples/native-select-icon'

module('Example | native-select-icon', function (hooks) {
  setupRenderingTest(hooks)

  test('the chevron replaced with chevrons-up-down, still decorative', async function (assert) {
    await render(<template><NativeSelectIcon /></template>)
    const sort = new NativeSelectHarness()

    assert.strictEqual(sort.label, 'Sort by')
    assert.strictEqual(sort.icon.querySelectorAll('path').length, 2, 'two chevrons')
    assert.true(sort.find(IconHarness).isDecorative)
    assert.strictEqual(getComputedStyle(sort.icon).width, '16px', 'sized as the chevron is')
    await sort.select('popular')
    assert.strictEqual(sort.selectedText, 'Most popular')
    await a11yAudit()
  })
})
