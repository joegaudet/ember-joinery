import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BreadcrumbHarness } from '@ember-joinery/test-support'
import BreadcrumbLink from 'docs-app/examples/breadcrumb-link'

module('Example | breadcrumb-link', function (hooks) {
  setupRenderingTest(hooks)

  test('your own links, made crumbs by the link modifier', async function (assert) {
    await render(<template><BreadcrumbLink /></template>)
    const breadcrumb = new BreadcrumbHarness()

    assert.deepEqual(breadcrumb.links, ['Home', 'Components'])
    for (const link of breadcrumb.parts('link')) {
      assert.dom(link).hasClass('jn-breadcrumb-link').hasAttribute('data-slot', 'breadcrumb-link')
    }
    assert.dom(breadcrumb.link('Home')).hasAttribute('href', '/')
    assert.strictEqual(breadcrumb.current, 'Breadcrumb')
    await a11yAudit()
  })
})
