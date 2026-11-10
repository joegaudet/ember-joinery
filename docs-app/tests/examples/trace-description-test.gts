import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TraceHarness } from '@ember-joinery/test-support'
import TraceDescriptionDemo from 'docs-app/examples/trace-description'

module('Example | trace-description', function (hooks) {
  setupRenderingTest(hooks)

  test('a diff stat, a duration and a count after the titles', async function (assert) {
    await render(<template><TraceDescriptionDemo /></template>)
    const [edit, test, search] = new TraceHarness().lines
    assert.strictEqual(edit!.description, '+48 −12')
    assert.strictEqual(test!.description, '14s')
    assert.strictEqual(search!.description, '8 results')
    assert.true(
      getComputedStyle(edit!.part('description')).fontFamily.includes('mono'),
      'font-mono on the diff stat',
    )
    assert.strictEqual(getComputedStyle(edit!.part('description')).flexShrink, '0')
    await a11yAudit()
  })
})
