import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ChartTooltipHarness } from '@ember-joinery/chart/test-support'
import ChartTooltip from 'docs-app/examples/chart-tooltip'

module('Example | chart-tooltip', function (hooks) {
  setupRenderingTest(hooks)

  test("the tooltip's label, names and indicators", async function (assert) {
    await render(<template><ChartTooltip /></template>)
    const [label, name, line, dot] = ChartTooltipHarness.findAll()
    assert.strictEqual(label!.label, 'Page Views')
    assert.deepEqual(label!.names, ['Desktop', 'Mobile'])
    assert.deepEqual(label!.entryValues, ['186', '80'])
    assert.strictEqual(label!.indicator, 'dot')

    assert.strictEqual(name!.label, null, 'hideLabel')
    assert.strictEqual(name!.indicator, 'dashed')
    assert.deepEqual(name!.names, ['Chrome', 'Firefox'])

    assert.strictEqual(line!.indicator, 'line')
    assert.strictEqual(line!.label, 'Page Views', 'one entry and a line: the label nests beside it')
    assert.deepEqual(line!.entryValues, ['12,486'])

    assert.strictEqual(dot!.label, null)
    assert.dom(dot!.items[0]!.indicator).hasStyle({ width: '10px', height: '10px' })
    await a11yAudit()
  })
})
