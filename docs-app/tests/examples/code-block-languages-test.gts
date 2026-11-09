import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import CodeBlockLanguages from 'docs-app/examples/code-block-languages'

module('Example | code-block-languages', function (hooks) {
  setupRenderingTest(hooks)

  test('CSS and Python highlighted, and a language not in the list as plain text', async function (assert) {
    await render(<template><CodeBlockLanguages /></template>)
    const [css, python, text] = CodeBlockHarness.findAll()
    assert.deepEqual(
      [css!.title, python!.title, text!.title],
      ['app/globals.css', 'main.py', 'notes.txt'],
    )
    assert.true(css!.isHighlighted, 'css loaded on first use')
    assert.true(python!.isHighlighted)
    assert.false(text!.isHighlighted)
    assert.strictEqual(text!.code, 'A language that is not in the list renders as plain text.')
    await a11yAudit()
  })
})
