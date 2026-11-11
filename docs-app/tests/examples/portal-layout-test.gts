import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import PortalLayout from 'docs-app/examples/portal-layout'

/** The example, in a root of the test's own: what each region of its layout holds. */
class LayoutHarness extends Harness {
  static override component = 'portal-layout'

  get header() {
    return this.#region('header')
  }

  get main() {
    return this.#region('main')
  }

  get sidebar() {
    return this.#region('sidebar')
  }

  get footer() {
    return this.#region('footer')
  }

  /** What a region holds, a line per portal. */
  #region(name: string): string[] {
    return this.element
      .querySelector(`.${name}-container`)!
      .textContent!.split('\n')
      .map(line => line.trim())
      .filter(Boolean)
  }
}

module('Example | portal-layout', function (hooks) {
  setupRenderingTest(hooks)

  test('two components fill the layout’s regions, each appending to them', async function (assert) {
    await render(
      <template>
        <div data-test-jn="portal-layout"><PortalLayout /></div>
      </template>,
    )
    const layout = new LayoutHarness()
    assert.deepEqual(layout.header, ['ExampleA header'])
    assert.deepEqual(layout.main, ['ExampleA main', 'ExampleB main'], 'appended, in order')
    assert.deepEqual(layout.sidebar, ['ExampleA sidebar', 'ExampleB sidebar'])
    assert.deepEqual(layout.footer, ['ExampleB footer'])
    await a11yAudit()
  })
})
