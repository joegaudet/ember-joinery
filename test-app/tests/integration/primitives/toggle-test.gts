import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { part } from '@ember-joinery/primitives/part'
import {
  Toggle,
  toggleSpec,
  toggleStateAttributes,
  type ToggleOptions,
} from '@ember-joinery/primitives/toggle'
import { ToggleHarness } from '@ember-joinery/test-support'

class State {
  @tracked pressed = false
  changes: boolean[] = []
  set = (pressed: boolean) => {
    this.changes.push(pressed)
    this.pressed = pressed
  }
}

module('Integration | primitives | toggle', function (hooks) {
  setupRenderingTest(hooks)

  test('it is a button with aria-pressed and data-state, which a press flips', async function (assert) {
    await render(
      <template>
        <Toggle @name="bold" as |pressed|>Bold {{if pressed "on" "off"}}</Toggle>
      </template>,
    )
    const bold = new ToggleHarness('bold')
    assert.dom(bold.element).hasTagName('button').hasAttribute('type', 'button')
    assert.dom(bold.element).hasAttribute('aria-pressed', 'false').hasAttribute('data-state', 'off')
    assert.false(bold.isPressed)
    assert.strictEqual(bold.text, 'Bold off')

    await bold.toggle()
    assert.true(bold.isPressed)
    assert.strictEqual(bold.state, 'on')
    assert.strictEqual(bold.text, 'Bold on', 'it yields the state')
    await bold.toggle()
    assert.false(bold.isPressed)
    await a11yAudit()
  })

  test('uncontrolled: @defaultPressed starts it, and @onPressedChange hears each change', async function (assert) {
    const changes: boolean[] = []
    const change = (pressed: boolean) => changes.push(pressed)
    await render(
      <template>
        <Toggle @defaultPressed={{true}} @onPressedChange={{change}}>Italic</Toggle>
      </template>,
    )
    const italic = new ToggleHarness()
    assert.true(italic.isPressed)
    await italic.toggle()
    await italic.toggle()
    assert.deepEqual(changes, [false, true])
    assert.true(italic.isPressed)
    await a11yAudit()
  })

  test('controlled: @pressed is the state, and @onPressedChange asks for a new one', async function (assert) {
    const state = new State()
    const asked: boolean[] = []
    const ask = (pressed: boolean) => asked.push(pressed)
    await render(
      <template>
        <Toggle @pressed={{state.pressed}} @onPressedChange={{state.set}} @name="taken">A</Toggle>
        <Toggle @pressed={{false}} @onPressedChange={{ask}} @name="kept">B</Toggle>
      </template>,
    )
    const taken = new ToggleHarness('taken')
    await taken.toggle()
    assert.true(taken.isPressed)
    assert.deepEqual(state.changes, [true])
    state.pressed = false
    await settled()
    assert.false(taken.isPressed, 'it follows @pressed')

    const kept = new ToggleHarness('kept')
    await kept.toggle()
    assert.deepEqual(asked, [true], 'it asked')
    assert.false(kept.isPressed, 'but stays as the caller has it')
    await a11yAudit()
  })

  test('keyboard: a native button, so Enter and Space press it', async function (assert) {
    await render(
      <template>
        <Toggle>Bold</Toggle>
      </template>,
    )
    const bold = new ToggleHarness()
    assert.strictEqual(bold.element.tabIndex, 0, 'in the tab order')
    assert.ok(
      bold.element instanceof HTMLButtonElement,
      'the browser presses it on Enter and Space',
    )
    await bold.focus()
    assert.true(bold.isFocused)
    await a11yAudit()
  })

  test('disabled: data-disabled, and a press does nothing', async function (assert) {
    const changes: boolean[] = []
    const change = (pressed: boolean) => changes.push(pressed)
    await render(
      <template>
        <Toggle @disabled={{true}} @onPressedChange={{change}}>Bold</Toggle>
      </template>,
    )
    const bold = new ToggleHarness()
    assert.true(bold.isDisabled)
    assert.dom(bold.element).hasAttribute('data-disabled', '')
    await bold.toggle().catch(() => undefined)
    assert.deepEqual(changes, [])
    assert.false(bold.isPressed)
    await a11yAudit()
  })

  test('a caller listener that prevents the default keeps it as it is', async function (assert) {
    const stop = (event: Event) => event.preventDefault()
    await render(
      <template>
        <Toggle {{on "click" stop}}>Bold</Toggle>
      </template>,
    )
    const bold = new ToggleHarness()
    await bold.toggle()
    assert.false(bold.isPressed)
    await a11yAudit()
  })

  test('@as, and toggleSpec on an element of your own', async function (assert) {
    const state = new State()
    const asToggle = part((options: ToggleOptions) => toggleSpec(options))
    await render(
      <template>
        <Toggle @as="span" role="button" tabindex="0" @name="span">Span</Toggle>
        <button
          type="button"
          data-test-jn="toggle"
          data-test-jn-name="own"
          {{asToggle pressed=state.pressed onPressedChange=state.set}}
        >Own</button>
      </template>,
    )
    assert.dom(new ToggleHarness('span').element).hasTagName('span')
    const own = new ToggleHarness('own')
    assert.false(own.isPressed)
    await own.toggle()
    assert.true(own.isPressed, 'the modifier asked, and the state came back')
    assert.strictEqual(own.state, 'on')
    assert.deepEqual(toggleStateAttributes({ pressed: true }), {
      'aria-pressed': 'true',
      'data-state': 'on',
      'data-disabled': undefined,
    })
    await a11yAudit()
  })
})
