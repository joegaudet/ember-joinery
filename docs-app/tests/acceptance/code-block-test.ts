import { module, test } from 'qunit'
import { setupApplicationTest } from 'docs-app/tests/helpers'
import { find, visit, waitUntil } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'

/**
 * Code Block's RTL and Typeset examples put bare paragraphs, a heading and inline code beside
 * the block, which on ui.shadcn.com sit on Tailwind's preflight. The guide gives those two
 * examples, and no others, the share of it they rely on (examples.css), on the parity route and
 * in the frame alike, keyed on the stage's own `data-parity` or `data-example`.
 */
module('Acceptance | code block examples', function (hooks) {
  setupApplicationTest(hooks)

  test('on the parity route, the bare text starts from the reset a Tailwind app gives it', async function (assert) {
    await visit('/parity/code-block-typeset')
    await waitUntil(() => find('[data-parity] h3'))
    const heading = getComputedStyle(find('[data-parity] h3')!)
    assert.strictEqual(heading.marginTop, '0px', 'no browser margin on the heading')
    assert.strictEqual(heading.fontWeight, '400', 'the text weight, as preflight gives it')
    assert.strictEqual(getComputedStyle(find('[data-parity] p')!).marginTop, '0px')
    assert.strictEqual(
      getComputedStyle(find('[data-parity] p > code')!).fontSize,
      getComputedStyle(find('[data-parity] p')!).fontSize,
      "inline code at the paragraph's size",
    )
    await a11yAudit({ rules: { region: { enabled: false } } })
  })

  test("in the guide's frame, the stage names its example", async function (assert) {
    await visit('/components/code-block.md')
    await waitUntil(() => find('[data-example="code-block-typeset"] h3'))
    const heading = getComputedStyle(find('[data-example="code-block-typeset"] h3')!)
    assert.strictEqual(heading.marginTop, '0px')
    assert.strictEqual(heading.fontWeight, '400')
    assert.strictEqual(
      getComputedStyle(find('[data-example="code-block-rtl"] p')!).marginTop,
      '0px',
    )
    await a11yAudit()
  })
})
