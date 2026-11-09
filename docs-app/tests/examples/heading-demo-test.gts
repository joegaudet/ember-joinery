import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { HeadingHarness, waitForObservers } from '@ember-joinery/test-support'
import HeadingDemo from 'docs-app/examples/heading-demo'

module('Example | heading-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('each heading takes its level from the sections around it', async function (assert) {
    await render(<template><HeadingDemo /></template>)
    // The demo renders once it is in view.
    await waitForObservers()
    const levels = HeadingHarness.findAll().map(heading => heading.level)

    // On its own, the demo starts at h1; on the guide's page, below the page's headings.
    assert.deepEqual(
      levels,
      [1, 2, 2, 2, 3, 4, 3],
      'top, nav, article, link, section, article, footer',
    )
    await a11yAudit()
  })
})
