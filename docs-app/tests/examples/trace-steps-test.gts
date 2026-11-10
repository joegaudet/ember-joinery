import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BadgeHarness, TraceCollapsibleHarness, TraceHarness } from '@ember-joinery/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import TraceSteps from 'docs-app/examples/trace-steps'

module('Example | trace-steps', function (hooks) {
  setupRenderingTest(hooks)

  test('a running summary that opens onto its steps', async function (assert) {
    await render(<template><TraceSteps /></template>)
    const [summary, search, cacheKey] = TraceCollapsibleHarness.findAll()
    assert.true(summary!.isOpen)
    assert.true(summary!.line.isRunning)
    assert.strictEqual(summary!.line.icons.length, 0, 'the summary has no icon of its own')
    const steps = summary!.find(TraceHarness)
    assert.deepEqual(steps.titles, [
      'Searched for the checkout build log',
      'Read the last twelve deploys',
      'Searching for the cache key',
    ])
    assert.true(steps.lines[1]!.isLink)
    await search!.open()
    assert.deepEqual(
      search!.findAll(BadgeHarness).map(badge => badge.text),
      ['vercel.com', 'github.com'],
    )
    assert.strictEqual(getComputedStyle(search!.content.firstElementChild!).display, 'flex')
    assert.true(cacheKey!.line.isRunning)
    await cacheKey!.open()
    assert.strictEqual(cacheKey!.find(CodeBlockHarness).code, 'cache key image optimization')
    await a11yAudit()
  })
})
