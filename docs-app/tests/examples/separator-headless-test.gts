import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SeparatorHarness } from '@ember-joinery/test-support'
import SeparatorHeadless from 'docs-app/examples/separator-headless'

module('Example | separator-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('decorative slashes in a breadcrumb, and a semantic <hr>', async function (assert) {
    await render(<template><SeparatorHeadless /></template>)
    const [first, second, rule] = SeparatorHarness.findAll()
    for (const slash of [first!, second!]) {
      assert.dom(slash.element).hasTagName('li').hasText('/')
      assert.true(slash.isDecorative, 'skipped by assistive technology')
    }
    assert.dom(rule!.element).hasTagName('hr')
    assert.false(rule!.isDecorative)
    assert.strictEqual(rule!.role, 'separator', "an <hr>'s own role")
    assert.strictEqual(rule!.orientation, 'horizontal')
    await a11yAudit()
  })
})
