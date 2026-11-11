import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { find, render, triggerEvent } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Label, preventLabelSelection } from '@ember-joinery/primitives/label'
import { LabelHarness } from '@ember-joinery/test-support'

/** Records, after the label's own listeners, whether a `mousedown` was prevented. */
function recorder() {
  const prevented: boolean[] = []
  return {
    prevented,
    record: (event: MouseEvent) => prevented.push(event.defaultPrevented),
  }
}

module('Integration | primitives | label', function (hooks) {
  setupRenderingTest(hooks)

  test('it is a native label that names its control and passes it a click', async function (assert) {
    await render(
      <template>
        <Label @name="email" for="email" class="mine">Your email address</Label>
        <input id="email" type="email" />
        <Label @name="wrapped"><input type="checkbox" /> Remember me</Label>
      </template>,
    )
    const email = new LabelHarness('email')
    assert.dom(email.element).hasTagName('label').hasClass('mine').hasAttribute('for', 'email')
    assert.dom(email.element).doesNotHaveAttribute('data-slot', 'no styles, so no slot')
    assert.strictEqual(email.text, 'Your email address')
    assert.strictEqual(email.control, find('#email'))
    await email.click()
    assert.dom('#email').isFocused('a click on the label focuses its input')

    const wrapped = new LabelHarness('wrapped')
    assert.strictEqual(wrapped.control, find('input[type="checkbox"]'))
    await wrapped.click()
    assert.dom('input[type="checkbox"]').isChecked('a click on the label toggles its checkbox')
    await a11yAudit()
  })

  test("a double click doesn't select its text, but a control inside it is left alone", async function (assert) {
    const { prevented, record } = recorder()
    await render(
      <template>
        {{! The listener is on an ancestor, so it hears the event after the label's own. }}
        <div {{on "mousedown" record}}>
          <Label @name="terms"><input type="checkbox" /> Accept terms</Label>
        </div>
      </template>,
    )
    const terms = new LabelHarness('terms')
    await triggerEvent(terms.element, 'mousedown', { detail: 1 })
    await triggerEvent(terms.element, 'mousedown', { detail: 2 })
    await triggerEvent(terms.control!, 'mousedown', { detail: 2 })
    assert.deepEqual(
      prevented,
      [false, true, false],
      'a single press is left alone, a double on the text is prevented, one on the input is not',
    )
    await a11yAudit()
  })

  test("your own mousedown listener runs before the label's", async function (assert) {
    const { prevented, record } = recorder()
    const order: string[] = []
    const mine = (event: MouseEvent) => order.push(`mine:${event.defaultPrevented}`)
    await render(
      <template>
        <div {{on "mousedown" record}}>
          <Label @name="name" for="name" {{on "mousedown" mine}}>Name</Label>
          <input id="name" />
        </div>
      </template>,
    )
    const name = new LabelHarness('name')
    await triggerEvent(name.element, 'mousedown', { detail: 2 })
    assert.deepEqual(order, ['mine:false'], "the caller's listener ran before the label's")
    assert.deepEqual(prevented, [true], 'then the label prevented the selection')
    await a11yAudit()
  })

  test('@as renders another tag, and preventLabelSelection works on its own', async function (assert) {
    const { prevented, record } = recorder()
    await render(
      <template>
        <div {{on "mousedown" record}}>
          <Label @as="span" @name="volume" id="volume-label">Volume</Label>
          <div role="slider" aria-labelledby="volume-label" aria-valuenow="5" tabindex="0"></div>
          <span id="plain" {{on "mousedown" preventLabelSelection}}>Plain</span>
        </div>
      </template>,
    )
    const volume = new LabelHarness('volume')
    assert.dom(volume.element).hasTagName('span')
    assert.strictEqual(volume.control, null, 'only a <label> has a control of its own')
    assert.false(volume.isControlDisabled)
    await triggerEvent(volume.element, 'mousedown', { detail: 2 })
    await triggerEvent('#plain', 'mousedown', { detail: 3 })
    assert.deepEqual(prevented, [true, true])
    await a11yAudit()
  })

  test('the harness reads whether its control is disabled', async function (assert) {
    await render(
      <template>
        <Label @name="off" for="off">Off</Label>
        <input id="off" disabled />
        <Label @name="on" for="on">On</Label>
        <input id="on" />
        <Label @name="none">Nothing</Label>
      </template>,
    )
    assert.true(new LabelHarness('off').isControlDisabled)
    assert.false(new LabelHarness('on').isControlDisabled)
    assert.false(new LabelHarness('none').isControlDisabled)
    assert.strictEqual(new LabelHarness('none').control, null)
    assert.throws(() => new LabelHarness('missing').element, /no label "missing" found/)
    await a11yAudit()
  })
})
