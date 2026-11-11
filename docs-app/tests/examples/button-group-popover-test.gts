import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonGroupHarness, PopoverHarness, TextareaHarness } from '@ember-joinery/test-support'
import ButtonGroupPopover from 'docs-app/examples/button-group-popover'

const style = (element: Element) => getComputedStyle(element)

module('Example | button-group-popover', function (hooks) {
  setupRenderingTest(hooks)

  test('Copilot, and a popover to describe a task in', async function (assert) {
    await render(<template><ButtonGroupPopover /></template>)
    const [copilot, open] = new ButtonGroupHarness().buttons
    assert.strictEqual(copilot!.label, 'Copilot')
    assert.strictEqual(style(copilot!.element).borderTopRightRadius, '0px', 'joined')
    assert.strictEqual(style(open!.element).borderTopLeftRadius, '0px')
    assert.strictEqual(style(open!.element).borderLeftWidth, '0px')

    const popover = new PopoverHarness()
    assert.strictEqual(popover.trigger, open!.element)
    await popover.open()
    assert.true(popover.isOpen)
    assert.strictEqual(popover.label, 'Start a new task with Copilot')
    assert.strictEqual(popover.description, 'Describe your task in natural language.')
    const task = new TextareaHarness()
    assert.strictEqual(task.label, 'Task Description')
    await task.fillIn('Fix the flaky test')
    assert.strictEqual(task.value, 'Fix the flaky test')
    await a11yAudit()
  })
})
