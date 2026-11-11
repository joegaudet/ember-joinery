import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BreadcrumbHarness } from '@ember-joinery/test-support'
import BreadcrumbBasic from 'docs-app/examples/breadcrumb-basic'

module('Example | breadcrumb-basic', function (hooks) {
  setupRenderingTest(hooks)

  test('two links and the current page, with chevrons between', async function (assert) {
    await render(<template><BreadcrumbBasic /></template>)
    const breadcrumb = new BreadcrumbHarness()

    assert.strictEqual(breadcrumb.label, 'breadcrumb')
    assert.deepEqual(breadcrumb.items, ['Home', 'Components', 'Breadcrumb'])
    assert.deepEqual(breadcrumb.links, ['Home', 'Components'])
    assert.strictEqual(breadcrumb.current, 'Breadcrumb')
    assert.strictEqual(breadcrumb.separators.length, 2)
    assert.dom(breadcrumb.separators[0]!.querySelector('svg')).hasClass('jn-rtl-flip', 'a chevron')
    await a11yAudit()
  })
})
