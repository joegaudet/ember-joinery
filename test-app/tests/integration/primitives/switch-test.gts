import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Switch } from '@ember-joinery/primitives/switch'
import { SwitchHarness, pressKey, tab } from '@ember-joinery/test-support'

module('Integration | primitives | switch', function (hooks) {
  setupRenderingTest(hooks)

  test('it is a button with the switch role, aria-checked, data-state and a thumb', async function (assert) {
    await render(
      <template>
        <Switch @name="airplane" id="airplane" as |s|>
          <s.Thumb />
          <span data-test-state>{{if s.isChecked "on" "off"}}</span>
        </Switch>
        <label for="airplane">Airplane Mode</label>
      </template>,
    )
    const airplane = new SwitchHarness('airplane')
    assert
      .dom(airplane.element)
      .hasTagName('button')
      .hasAttribute('type', 'button')
      .hasAttribute('role', 'switch')
      .hasAttribute('aria-checked', 'false')
      .hasAttribute('data-state', 'unchecked')
      .hasAttribute('value', 'on')
    assert.dom(airplane.thumb).hasTagName('span').hasAttribute('data-state', 'unchecked')
    assert.strictEqual(airplane.label, 'Airplane Mode')
    assert.strictEqual(airplane.size, null)
    assert.dom('[data-test-state]').hasText('off')

    await airplane.toggle()
    assert.true(airplane.isChecked)
    assert.dom(airplane.thumb).hasAttribute('data-state', 'checked')
    assert.dom('[data-test-state]').hasText('on', 'it yields isChecked')
    await click('label[for="airplane"]')
    assert.false(airplane.isChecked, 'its label toggles it')
    await a11yAudit()
  })

  test('controlled and uncontrolled, as in Radix', async function (assert) {
    class State {
      @tracked on = true
    }
    const state = new State()
    const heard: boolean[] = []
    const change = (checked: boolean) => {
      heard.push(checked)
      state.on = checked
    }
    await render(
      <template>
        <Switch @name="mine" @defaultChecked={{true}} aria-label="Mine" />
        <Switch
          @name="theirs"
          @checked={{state.on}}
          @onCheckedChange={{change}}
          aria-label="Theirs"
        />
      </template>,
    )
    const mine = new SwitchHarness('mine')
    assert.true(mine.isChecked, '@defaultChecked')
    await mine.uncheck()
    assert.false(mine.isChecked)
    await mine.check()
    assert.true(mine.isChecked)

    const theirs = new SwitchHarness('theirs')
    await theirs.toggle()
    assert.deepEqual(heard, [false])
    assert.false(theirs.isChecked)
    state.on = true
    await settled()
    assert.true(theirs.isChecked, 'it follows @checked')
    await a11yAudit()
  })

  test('keyboard: Tab reaches it, and Space and Enter toggle it (a native button)', async function (assert) {
    await render(
      <template>
        <Switch @name="wifi" aria-label="Wi-Fi" />
        <Switch @name="off" @disabled={{true}} aria-label="Off" as |s|><s.Thumb /></Switch>
      </template>,
    )
    const wifi = new SwitchHarness('wifi')
    await tab()
    assert.true(wifi.isFocused)
    assert.ok(wifi.element instanceof HTMLButtonElement, 'the browser clicks it on Space and Enter')
    assert.false(await pressKey('Enter'), 'Enter is left to the button, as in Radix')

    const off = new SwitchHarness('off')
    assert.true(off.isDisabled)
    assert.dom(off.element).hasAttribute('data-disabled', '')
    assert.dom(off.thumb).hasAttribute('data-disabled', '')
    await click(off.element).catch(() => undefined)
    assert.false(off.isChecked)
    await a11yAudit()
  })

  test('in a form: a hidden checkbox submits it, and @required needs it on', async function (assert) {
    await render(
      <template>
        <form id="settings">
          <Switch @name="wifi" name="wifi" @required={{true}} aria-label="Wi-Fi" />
          <Switch @name="dark" name="dark" value="1" @defaultChecked={{true}} aria-label="Dark" />
        </form>
      </template>,
    )

    const formElement = document.querySelector<HTMLFormElement>('#settings')!
    const wifi = new SwitchHarness('wifi')
    assert.true(wifi.isRequired)
    assert.dom(wifi.input).hasAttribute('name', 'wifi').hasAttribute('type', 'checkbox')
    assert.false(formElement.checkValidity())
    await wifi.toggle()
    assert.true(formElement.checkValidity())
    assert.deepEqual(
      [...new FormData(formElement).entries()],
      [
        ['wifi', 'on'],
        ['dark', '1'],
      ],
    )
    await a11yAudit()
  })

  test('the thumb takes content and @as', async function (assert) {
    await render(
      <template>
        <Switch @name="mode" @as="span" tabindex="0" aria-label="Mode" as |s|>
          <s.Thumb @as="b">{{if s.isChecked "☾" "☀"}}</s.Thumb>
        </Switch>
      </template>,
    )
    const mode = new SwitchHarness('mode')
    assert.dom(mode.element).hasTagName('span')
    assert.dom(mode.thumb).hasTagName('b').hasText('☀')
    await mode.toggle()
    assert.dom(mode.thumb).hasText('☾')
    await a11yAudit()
  })
})
