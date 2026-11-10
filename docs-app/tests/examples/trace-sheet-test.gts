import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SheetHarness, TraceLineHarness } from '@ember-joinery/test-support'
import TraceSheet from 'docs-app/examples/trace-sheet'

module('Example | trace-sheet', function (hooks) {
  setupRenderingTest(hooks)

  test('a row that opens a sheet listing the files read', async function (assert) {
    await render(<template><TraceSheet /></template>)
    const line = new TraceLineHarness()
    assert.strictEqual(line.title, 'Explored 4 files')
    const sheet = new SheetHarness()
    await line.click()
    assert.true(sheet.isOpen)
    assert.strictEqual(sheet.label, 'Explored 4 files')
    assert.strictEqual(sheet.content!.querySelectorAll('li').length, 4)
    await a11yAudit()
  })
})
