import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BreadcrumbHarness, DropdownMenuHarness, child } from '@ember-joinery/test-support'
import BreadcrumbRtl from 'docs-app/examples/breadcrumb-rtl'

class ArabicBreadcrumb extends BreadcrumbHarness {
  @child(DropdownMenuHarness) declare components: DropdownMenuHarness
}

module('Example | breadcrumb-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, right to left, its menu lined up with the crumb’s right', async function (assert) {
    await render(<template><BreadcrumbRtl /></template>)
    const breadcrumb = new ArabicBreadcrumb()
    assert.dom(breadcrumb.element).hasAttribute('dir', 'rtl')
    assert.deepEqual(breadcrumb.links, ['الرئيسية'])
    assert.strictEqual(breadcrumb.current, 'مسار التنقل')
    await breadcrumb.components.open()
    assert.deepEqual(breadcrumb.components.items, ['التوثيق', 'السمات', 'جيت هاب'])
    // Measured at rest, once its zoom-in has run.
    for (const animation of breadcrumb.components.content!.getAnimations()) animation.finish()
    const trigger = breadcrumb.components.trigger.getBoundingClientRect()
    const content = breadcrumb.components.content!.getBoundingClientRect()
    assert.true(Math.abs(content.right - trigger.right) <= 1, 'start is the right edge')
    await a11yAudit()
  })
})
