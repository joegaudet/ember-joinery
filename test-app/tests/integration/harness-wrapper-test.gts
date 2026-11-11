import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, attributes, selectors } from '@ember-joinery/test-support'

class PanelHarness extends Harness {
  static override component = 'panel'
}

class FrameHarness extends Harness {
  static override component = 'frame'
}

class BadgeHarness extends Harness {
  static override component = 'badge'
}

module('Integration | harness | wrappers', function (hooks) {
  setupRenderingTest(hooks)

  test('a part inside a wrapper belongs to the component around the wrapper', async function (assert) {
    await render(
      <template>
        <section data-test-jn="panel" aria-label="Panel">
          <div data-test-jn="frame" data-test-jn-wrapper>
            <div data-test-jn="frame" data-test-jn-wrapper data-test-jn-name="inner">
              <p data-test-jn-part="body">Body</p>
            </div>
            <span data-test-jn="badge"><span data-test-jn-part="label">New</span></span>
          </div>
        </section>
      </template>,
    )
    const panel = new PanelHarness()
    assert.dom(panel.part('body')).hasText('Body', 'through two wrappers')
    assert.strictEqual(
      panel.queryPart('label'),
      null,
      'a component that isn’t a wrapper keeps its own',
    )

    const frame = panel.find(FrameHarness)
    assert.true(frame.exists, 'a wrapper is found as a component')
    assert.deepEqual(frame.parts('body'), [], 'and has no parts of its own')
    assert.true(frame.find(FrameHarness, 'inner').exists, 'it scopes the components inside it')
    assert.dom(frame.find(BadgeHarness).part('label')).hasText('New')
    await a11yAudit()
  })

  test('a wrapper can be a part itself', async function (assert) {
    await render(
      <template>
        <section data-test-jn="panel" aria-label="Panel">
          <h2 data-test-jn="frame" data-test-jn-wrapper data-test-jn-part="title">
            Title
            <span data-test-jn-part="count">3</span>
          </h2>
        </section>
      </template>,
    )
    const panel = new PanelHarness()
    assert.dom(panel.part('title')).hasText('Title 3')
    assert.dom(panel.part('count')).hasText('3')
    await a11yAudit()
  })

  test('the attribute and its selector', async function (assert) {
    assert.strictEqual(attributes.wrapper, 'data-test-jn-wrapper')
    assert.strictEqual(selectors.wrapper(), '[data-test-jn-wrapper]')
    await render(
      <template>
        <p>Nothing to audit</p>
      </template>,
    )
    await a11yAudit()
  })
})
