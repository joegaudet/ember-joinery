import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BubbleHarness, ButtonHarness, CollapsibleHarness } from '@ember-joinery/test-support'
import BubbleCollapsible from 'docs-app/examples/bubble-collapsible'

/**
 * The audits, but for the contrast of the Show more button: upstream's example draws it
 * `text-muted-foreground` on the muted bubble's `--muted`, under the 4.5:1 WCAG AA asks of its
 * 14px text (the Bubble page's Accessibility notes say so). One audit runs every other rule on
 * it; the other checks the contrast of everything else.
 */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_SHOW_MORE = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="bubble-content"] [data-slot="collapsible-trigger"]']],
}

module('Example | bubble-collapsible', function (hooks) {
  setupRenderingTest(hooks)

  test('a long bubble shows a preview, and Show more reveals the rest', async function (assert) {
    await render(<template><BubbleCollapsible /></template>)
    const [, long] = BubbleHarness.findAll()
    const more = new CollapsibleHarness()
    const button = more.find(ButtonHarness)

    assert.strictEqual(long!.align, 'end')
    assert.false(more.isOpen)
    assert.strictEqual(button.label, 'Show more')
    assert.strictEqual(button.variant, 'link')
    const text = () => more.content!.querySelector('div')!
    const shown = () => text().textContent!
    assert.ok(shown().startsWith('The accessibility review found two focus states'))
    assert.strictEqual(shown().length, 183, 'a preview: the first 180 characters, and "..."')
    assert.ok(shown().endsWith('...'))
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_SHOW_MORE, { runOnly: ['color-contrast'] })

    await more.open()
    assert.true(more.isOpen)
    assert.strictEqual(button.label, 'Show less')
    assert.ok(shown().endsWith('choose their own focus treatment later.'), 'the whole text')
    assert.strictEqual(
      getComputedStyle(text()).whiteSpace,
      'pre-line',
      'whitespace-pre-line keeps its paragraphs apart',
    )
    const line = Number.parseFloat(getComputedStyle(text()).lineHeight)
    assert.ok(text().offsetHeight > line * 8, 'four paragraphs, with blank lines between them')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_SHOW_MORE, { runOnly: ['color-contrast'] })

    await button.click()
    assert.false(more.isOpen, 'Show less hides it again')
    assert.strictEqual(button.label, 'Show more')
  })
})
