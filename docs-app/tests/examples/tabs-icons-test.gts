import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { IconHarness, TabsHarness } from '@ember-joinery/test-support'
import TabsIcons from 'docs-app/examples/tabs-icons'

module('Example | tabs-icons', function (hooks) {
  setupRenderingTest(hooks)

  test('each tab has an icon before its label', async function (assert) {
    await render(<template><TabsIcons /></template>)
    const tabs = new TabsHarness()
    assert.strictEqual(tabs.label('preview'), 'Preview')
    assert.strictEqual(tabs.label('code'), 'Code')
    const icons = tabs.findAll(IconHarness)
    assert.strictEqual(icons.length, 2)
    assert.true(icons[0]!.isDecorative)
    assert.strictEqual(getComputedStyle(icons[0]!.element).width, '16px', 'size-4')

    await tabs.select('code')
    assert.strictEqual(tabs.selected, 'code')
    await a11yAudit()
  })
})
