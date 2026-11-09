import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import PortalLayout from 'docs-app/examples/portal-layout'

/** What a region of the layout holds, a line per portal. */
function region(name: string): string[] {
  return document
    .querySelector(`.${name}-container`)!
    .textContent!.split('\n')
    .map(line => line.trim())
    .filter(Boolean)
}

module('Example | portal-layout', function (hooks) {
  setupRenderingTest(hooks)

  test('two components fill the layout’s regions, each appending to them', async function (assert) {
    await render(<template><PortalLayout /></template>)
    assert.deepEqual(region('header'), ['ExampleA header'])
    assert.deepEqual(region('main'), ['ExampleA main', 'ExampleB main'], 'appended, in order')
    assert.deepEqual(region('sidebar'), ['ExampleA sidebar', 'ExampleB sidebar'])
    assert.deepEqual(region('footer'), ['ExampleB footer'])
    await a11yAudit()
  })
})
