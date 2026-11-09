import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BreadcrumbHarness, IconHarness } from '@ember-joinery/test-support'
import BreadcrumbSeparator from 'docs-app/examples/breadcrumb-separator'

module('Example | breadcrumb-separator', function (hooks) {
  setupRenderingTest(hooks)

  test('dots in place of the chevrons', async function (assert) {
    await render(<template><BreadcrumbSeparator /></template>)
    const breadcrumb = new BreadcrumbHarness()

    assert.deepEqual(breadcrumb.items, ['Home', 'Components', 'Breadcrumb'])
    assert.dom(breadcrumb.link('Home')).hasAttribute('href', '/')
    assert.dom(breadcrumb.link('Components')).hasAttribute('href', '/components')
    for (const separator of breadcrumb.separators) {
      const dot = new IconHarness({ within: separator })
      assert.true(dot.isDecorative)
      assert.dom(dot.element.querySelector('circle')).exists("lucide's dot")
      assert.dom(dot.element).doesNotHaveClass('jn-rtl-flip', 'no chevron')
    }
    await a11yAudit()
  })
})
