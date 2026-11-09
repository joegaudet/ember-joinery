import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BreadcrumbHarness, DropdownMenuHarness, child } from '@ember-joinery/test-support'
import BreadcrumbDropdown from 'docs-app/examples/breadcrumb-dropdown'

class ComponentsBreadcrumb extends BreadcrumbHarness {
  @child(DropdownMenuHarness) declare components: DropdownMenuHarness
}

module('Example | breadcrumb-dropdown', function (hooks) {
  setupRenderingTest(hooks)

  test('a crumb that opens a menu, between dot separators', async function (assert) {
    await render(<template><BreadcrumbDropdown /></template>)
    const breadcrumb = new ComponentsBreadcrumb()
    assert.deepEqual(breadcrumb.links, ['Home'])
    assert.strictEqual(breadcrumb.current, 'Breadcrumb')
    const trigger = breadcrumb.components.trigger
    assert.dom(trigger).hasTagName('button').hasText('Components')
    assert.strictEqual(getComputedStyle(trigger.querySelector('svg')!).width, '14px', 'size-3.5')
    await a11yAudit()

    await breadcrumb.components.openWithKeyboard()
    assert.deepEqual(breadcrumb.components.items, ['Documentation', 'Themes', 'GitHub'])
    assert.strictEqual(breadcrumb.components.highlighted, 'Documentation')
    await a11yAudit()
  })
})
