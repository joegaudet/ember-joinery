import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BreadcrumbHarness } from '@ember-joinery/test-support'
import BreadcrumbHeadless from 'docs-app/examples/breadcrumb-headless'

module('Example | breadcrumb-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('a named path whose slashes assistive technology skips', async function (assert) {
    await render(<template><BreadcrumbHeadless /></template>)
    const breadcrumb = new BreadcrumbHarness()

    assert.strictEqual(breadcrumb.label, 'Breadcrumb')
    assert.deepEqual(breadcrumb.items, ['Home', 'Docs', 'Breadcrumb'])
    assert.strictEqual(breadcrumb.current, 'Breadcrumb')
    assert.deepEqual(
      breadcrumb.separators.map(separator => separator.getAttribute('aria-hidden')),
      ['true', 'true'],
    )
    await a11yAudit()
  })
})
