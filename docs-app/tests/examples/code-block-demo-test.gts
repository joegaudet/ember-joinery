import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness } from '@ember-joinery/test-support'
import { CodeBlockHarness, setupClipboard } from '@ember-joinery/code-block/test-support'
import CodeBlockDemo from 'docs-app/examples/code-block-demo'

module('Example | code-block-demo', function (hooks) {
  setupRenderingTest(hooks)
  const clipboard = setupClipboard(hooks)

  test('a highlighted, numbered file with wrap, download and copy actions', async function (assert) {
    await render(<template><CodeBlockDemo /></template>)
    const block = new CodeBlockHarness()

    assert.strictEqual(block.title, 'app/api/chat/route.ts')
    assert.true(block.isHighlighted, 'Shiki has coloured it')
    assert.true(block.isNumbered)
    assert.strictEqual(block.lines.length, 13)
    assert.deepEqual(block.highlightedLines, [5, 6, 7, 8, 9], 'the streamText call stands out')

    const [wrap, download] = ButtonHarness.findAll()
    assert.strictEqual(wrap!.label, 'Wrap lines')
    assert.false(wrap!.isPressed)
    assert.false(block.isWrapped)
    await wrap!.click()
    assert.true(wrap!.isPressed, 'a toggle: aria-pressed says it is on')
    assert.true(block.isWrapped)

    // Download builds a file and clicks a link to it; catch the click instead of downloading.
    const { click } = HTMLAnchorElement.prototype
    let filename: string | undefined
    HTMLAnchorElement.prototype.click = function (this: HTMLAnchorElement) {
      filename = this.download
    }
    try {
      await download!.click()
    } finally {
      HTMLAnchorElement.prototype.click = click
    }
    assert.strictEqual(download!.label, 'Download')
    assert.strictEqual(filename, 'route.ts')

    await block.copy()
    assert.strictEqual(clipboard.text, block.code, 'Copy copies the whole file')
    assert.strictEqual(block.copyLabel, 'Copied')
    await a11yAudit()
  })
})
