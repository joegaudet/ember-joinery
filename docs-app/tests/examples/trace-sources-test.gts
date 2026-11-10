import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TraceCollapsibleHarness, TraceHarness } from '@ember-joinery/test-support'
import TraceSources from 'docs-app/examples/trace-sources'

module('Example | trace-sources', function (hooks) {
  setupRenderingTest(hooks)

  test('an open row whose detail is a trace of links', async function (assert) {
    await render(<template><TraceSources /></template>)
    const row = new TraceCollapsibleHarness()
    assert.true(row.isOpen)
    assert.strictEqual(row.line.title, 'Used 3 sources')
    const sources = row.find(TraceHarness)
    assert.strictEqual(sources.lines.length, 3)
    assert.true(sources.lines.every(line => line.opensInNewTab))
    assert.strictEqual(sources.lines[2]!.href, 'https://pnpm.io/settings#minimumreleaseage')
    await a11yAudit()
  })
})
