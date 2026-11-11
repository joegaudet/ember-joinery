import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BreadcrumbHarness } from '@ember-joinery/test-support'
import BreadcrumbEllipsis from 'docs-app/examples/breadcrumb-ellipsis'

module('Example | breadcrumb-ellipsis', function (hooks) {
  setupRenderingTest(hooks)

  test('the crumbs between Home and Components collapse into an ellipsis', async function (assert) {
    await render(<template><BreadcrumbEllipsis /></template>)
    const breadcrumb = new BreadcrumbHarness()

    assert.true(breadcrumb.isCollapsed)
    assert.deepEqual(
      breadcrumb.items,
      ['Home', '', 'Components', 'Breadcrumb'],
      'it reads as nothing',
    )
    assert.dom(breadcrumb.link('Components')).hasAttribute('href', '/docs/components')
    const ellipsis = breadcrumb.part('ellipsis')
    assert.dom(ellipsis).hasAttribute('aria-hidden', 'true')
    assert.strictEqual(getComputedStyle(ellipsis).width, '20px', 'size-5')
    await a11yAudit()
  })
})
