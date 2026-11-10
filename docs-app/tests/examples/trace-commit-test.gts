import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SheetHarness, TraceCollapsibleHarness, TraceHarness } from '@ember-joinery/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import TraceCommit from 'docs-app/examples/trace-commit'

module('Example | trace-commit', function (hooks) {
  setupRenderingTest(hooks)

  test('a commit row with a line for each file, each opening its diff', async function (assert) {
    await render(<template><TraceCommit /></template>)
    const commit = new TraceCollapsibleHarness()
    assert.strictEqual(commit.line.title, 'Committed a1b2c3: Fix the login redirect')
    const files = commit.find(TraceHarness)
    assert.deepEqual(files.titles, ['Edited app/login/page.tsx', 'Added lib/auth/redirect.ts'])
    assert.deepEqual(
      files.lines.map(line => line.description),
      ['+2 −2', '+7 −0'],
    )
    for (const line of files.lines) {
      const trigger = line.control!
      assert.strictEqual(
        getComputedStyle(trigger).display,
        'flex',
        "each file's sheet trigger is the row",
      )
      assert.strictEqual(
        trigger.getBoundingClientRect().width,
        line.element.getBoundingClientRect().width,
        'as wide as its line',
      )
    }
    await files.lines[1]!.click()
    const [, added] = SheetHarness.findAll()
    assert.true(added!.isOpen)
    assert.strictEqual(added!.label, 'lib/auth/redirect.ts')
    const diff = added!.find(CodeBlockHarness)
    assert.strictEqual(diff.addedLines.length, 7, 'every line after the hunk is added')
    assert.strictEqual(diff.removedLines.length, 0)
    assert.true(diff.code.startsWith('@@ -0,0 +1,7 @@'), 'the hunk header, whole')
    await a11yAudit()
  })
})
