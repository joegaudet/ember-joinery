import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BubbleHarness, ButtonHarness, PopoverHarness } from '@ember-joinery/test-support'
import BubblePopover from 'docs-app/examples/bubble-popover'

/** The audits, but for the destructive bubble's text (see bubble-variants-test.gts). */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_THE_DESTRUCTIVE_TEXT = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="bubble"][data-variant="destructive"] > [data-slot="bubble-content"]']],
}

module('Example | bubble-popover', function (hooks) {
  setupRenderingTest(hooks)

  test("a failed command's bubble opens the full error in a popover", async function (assert) {
    await render(<template><BubblePopover /></template>)
    const [, failed] = BubbleHarness.findAll()
    assert.strictEqual(failed!.variant, 'destructive')
    assert.strictEqual(failed!.text, 'Failed to run the command.')

    const details = failed!.find(ButtonHarness)
    assert.strictEqual(details.label, 'Show error details')
    const popover = new PopoverHarness()
    assert.false(popover.isOpen)

    await details.click()
    assert.true(popover.isOpen)
    assert.strictEqual(popover.title, 'Command failed with exit code 1')
    assert.strictEqual(
      popover.description,
      'ENOENT: no such file or directory, open pnpm-lock.yaml',
    )
    assert.strictEqual(details.element.getAttribute('aria-expanded'), 'true')
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_DESTRUCTIVE_TEXT, { runOnly: ['color-contrast'] })

    await popover.pressEscape()
    assert.false(popover.isOpen)
    assert.true(details.isFocused, 'focus is back on the button')
  })
})
