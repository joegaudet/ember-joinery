import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SelectHarness } from '@ember-joinery/test-support'
import SelectScrollable from 'docs-app/examples/select-scrollable'

module('Example | select-scrollable', function (hooks) {
  setupRenderingTest(hooks)

  test('a long list of timezones scrolls, with typeahead to find one', async function (assert) {
    await render(<template><SelectScrollable /></template>)
    const select = new SelectHarness()
    assert.strictEqual(select.valueText, 'Select a timezone')
    await select.open()
    assert.strictEqual(select.options.length, 27)
    assert.deepEqual(select.groups, [
      'North America',
      'Europe & Africa',
      'Asia',
      'Australia & Pacific',
      'South America',
    ])
    await select.typeahead('Fiji')
    assert.dom(select.option('fjt')).isFocused('typing finds Fiji Time')
    await settled()
    assert.true(select.canScrollUp, 'the options above it scroll up')
    await select.pressKey('Enter')
    assert.strictEqual(select.valueText, 'Fiji Time')
    await a11yAudit()
  })
})
