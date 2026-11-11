import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SkeletonHarness } from '@ember-joinery/test-support'
import SkeletonForm from 'docs-app/examples/skeleton-form'

module('Example | skeleton-form', function (hooks) {
  setupRenderingTest(hooks)

  test('two labelled fields and a button, loading', async function (assert) {
    await render(<template><SkeletonForm /></template>)
    const sizes = SkeletonHarness.findAll().map(skeleton => skeleton.height)
    assert.deepEqual(sizes, [16, 32, 16, 32, 32], 'label, input, label, input, button')
    const [label, input, , , button] = SkeletonHarness.findAll()
    assert.strictEqual(label!.width, 80, 'w-20')
    assert.strictEqual(button!.width, 96, 'w-24')
    assert.ok(input!.width > button!.width, 'the inputs are full width')
    await a11yAudit()
  })
})
