import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonGroupHarness, KbdHarness, TooltipHarness } from '@ember-joinery/test-support'
import KbdTooltip from 'docs-app/examples/kbd-tooltip'

const style = (element: Element) => getComputedStyle(element)

module('Example | kbd-tooltip', function (hooks) {
  setupRenderingTest(hooks)

  test('two joined buttons, each with a tooltip naming its keys', async function (assert) {
    await render(<template><KbdTooltip /></template>)
    const [save, print] = new ButtonGroupHarness().buttons
    // Each button is inside its tooltip's root, which the group's rules reach through.
    assert.strictEqual(style(save!.element).borderTopRightRadius, '0px', 'joined')
    assert.strictEqual(style(print!.element).borderTopLeftRadius, '0px')
    assert.strictEqual(style(print!.element).borderLeftWidth, '0px')
    assert.notStrictEqual(style(save!.element).borderTopLeftRadius, '0px')
    assert.notStrictEqual(style(print!.element).borderTopRightRadius, '0px')

    const [saveTip, printTip] = TooltipHarness.findAll()
    await saveTip!.hover()
    assert.strictEqual(saveTip!.text, 'Save Changes S')
    assert.deepEqual(
      saveTip!.findAll(KbdHarness).map(kbd => kbd.element.textContent?.trim()),
      ['S'],
    )
    await a11yAudit()

    await saveTip!.unhover()
    await printTip!.focus()
    assert.true(printTip!.isOpen)
    assert.strictEqual(printTip!.text, 'Print Document Ctrl P')
    assert.deepEqual(
      printTip!.findAll(KbdHarness).map(kbd => kbd.element.textContent?.trim()),
      ['Ctrl', 'P'],
    )
    await a11yAudit()
  })
})
