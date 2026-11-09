import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, rerender, settled, triggerEvent } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { nativeValue } from '@ember-joinery/primitives/native-value'
import { InputHarness, NativeSelectHarness, TextareaHarness } from '@ember-joinery/test-support'

/** The values a callback heard, in order. */
function recorder(): { values: string[]; record: (value: string) => void } {
  const values: string[] = []
  return { values, record: (value: string) => void values.push(value) }
}

class State {
  @tracked value: string | undefined
  constructor(value?: string) {
    this.value = value
  }
}

module('Integration | primitives | native-value', function (hooks) {
  setupRenderingTest(hooks)

  test('uncontrolled, it starts from defaultValue, keeps what is typed, and reports it', async function (assert) {
    const heard = recorder()
    await render(
      <template>
        <input
          aria-label="Name"
          data-test-jn="input"
          {{nativeValue defaultValue="Ada" onValueChange=heard.record}}
        />
        <textarea
          aria-label="Bio"
          data-test-jn="textarea"
          {{nativeValue defaultValue="Hello"}}
        ></textarea>
      </template>,
    )
    const field = new InputHarness()
    assert.strictEqual(field.value, 'Ada', 'it shows the default')
    assert.strictEqual(new TextareaHarness().value, 'Hello', 'a textarea too')

    await field.fillIn('Grace')
    assert.strictEqual(field.value, 'Grace', 'it keeps its own value')
    await field.typeIn('!')
    assert.strictEqual(field.value, 'Grace!')
    assert.deepEqual(heard.values, ['Grace', 'Grace!'], 'every change is reported once')
    await a11yAudit()
  })

  test('uncontrolled with no default, it starts from what the control shows', async function (assert) {
    const heard = recorder()
    await render(
      <template>
        <input aria-label="City" data-test-jn="input" value="Paris" {{nativeValue}} />
        <div data-test-jn="native-select">
          <select
            aria-label="Fruit"
            data-test-jn-part="select"
            {{nativeValue onValueChange=heard.record}}
          >
            <option value="apple">Apple</option>
            <option value="pear" selected>Pear</option>
          </select>
        </div>
      </template>,
    )
    assert.strictEqual(new InputHarness().value, 'Paris', 'its value attribute')
    const picker = new NativeSelectHarness()
    assert.strictEqual(picker.value, 'pear', 'a select keeps its selected option')
    await picker.select('apple')
    assert.strictEqual(picker.value, 'apple')
    assert.deepEqual(heard.values, ['apple'])
    await a11yAudit()
  })

  test('controlled, it shows the value, and the caller decides every change', async function (assert) {
    const state = new State('ada')
    const heard = recorder()
    const lowerCase = (value: string) => {
      heard.record(value)
      state.value = value.toLowerCase()
    }
    await render(
      <template>
        <input
          aria-label="Username"
          data-test-jn="input"
          {{nativeValue value=state.value onValueChange=lowerCase}}
        />
      </template>,
    )
    const field = new InputHarness()
    assert.strictEqual(field.value, 'ada')

    await field.fillIn('GRACE')
    assert.deepEqual(heard.values, ['GRACE'], 'the change goes to the caller')
    assert.strictEqual(field.value, 'grace', 'and it shows what the caller made of it')

    state.value = 'lin'
    await settled()
    assert.strictEqual(field.value, 'lin', 'a change from outside shows')
    assert.deepEqual(heard.values, ['GRACE'], 'without being reported back')
    await a11yAudit()
  })

  test('controlled, a change the caller refuses is undone', async function (assert) {
    const state = new State('fixed')
    const heard = recorder()
    await render(
      <template>
        <input
          aria-label="Fixed"
          data-test-jn="input"
          {{nativeValue value=state.value onValueChange=heard.record}}
        />
        <div data-test-jn="native-select">
          <select
            aria-label="Plan"
            data-test-jn-part="select"
            {{nativeValue value="free" onValueChange=heard.record}}
          >
            <option value="free">Free</option>
            <option value="pro">Pro</option>
          </select>
        </div>
      </template>,
    )
    const field = new InputHarness()
    await field.fillIn('changed')
    assert.deepEqual(heard.values, ['changed'], 'the caller heard it')
    assert.strictEqual(field.value, 'fixed', 'and the input shows the value it was given')

    const picker = new NativeSelectHarness()
    await picker.select('pro')
    assert.deepEqual(heard.values, ['changed', 'pro'])
    assert.strictEqual(picker.value, 'free', 'a select too')
    await a11yAudit()
  })

  test('controlled, a change is left alone while an input method composes', async function (assert) {
    const heard = recorder()
    await render(
      <template>
        <input
          aria-label="Word"
          data-test-jn="input"
          {{nativeValue value="" onValueChange=heard.record}}
        />
      </template>,
    )
    const field = new InputHarness()
    field.control.value = 'に'
    field.control.dispatchEvent(new InputEvent('input', { bubbles: true, isComposing: true }))
    await settled()
    assert.deepEqual(heard.values, ['に'])
    assert.strictEqual(field.value, 'に', 'not undone mid-composition')
    await triggerEvent(field.control, 'compositionend')
    assert.strictEqual(field.value, '', 'but once it is done')
    await a11yAudit()
  })

  test('a form reset goes back to the starting value, and says so', async function (assert) {
    const uncontrolled = recorder()
    const controlled = recorder()
    const state = new State('start')
    const take = (value: string) => {
      controlled.record(value)
      state.value = value
    }
    await render(
      <template>
        <form aria-label="Profile">
          <input
            aria-label="Name"
            data-test-jn="input"
            data-test-jn-name="uncontrolled"
            {{nativeValue defaultValue="Ada" onValueChange=uncontrolled.record}}
          />
          <input
            aria-label="Nickname"
            data-test-jn="input"
            data-test-jn-name="controlled"
            {{nativeValue value=state.value onValueChange=take}}
          />
          <button type="reset">Reset</button>
        </form>
      </template>,
    )
    const name = new InputHarness('uncontrolled')
    const nickname = new InputHarness('controlled')
    await name.fillIn('Grace')
    await nickname.fillIn('later')
    assert.strictEqual(state.value, 'later')

    await click('button[type="reset"]')
    assert.strictEqual(name.value, 'Ada', 'uncontrolled, back to its default')
    assert.deepEqual(uncontrolled.values, ['Grace', 'Ada'], 'and the change is reported')
    assert.deepEqual(controlled.values, ['later', 'start'], 'controlled, the caller is asked')
    assert.strictEqual(nickname.value, 'start', 'and took it')
    await a11yAudit()
  })

  test("a form reset that's cancelled changes nothing", async function (assert) {
    const heard = recorder()
    const cancel = (event: Event) => event.preventDefault()
    await render(
      <template>
        <form aria-label="Profile" {{on "reset" cancel}}>
          <input
            aria-label="Name"
            data-test-jn="input"
            {{nativeValue defaultValue="Ada" onValueChange=heard.record}}
          />
        </form>
      </template>,
    )
    const name = new InputHarness()
    await name.fillIn('Grace')
    await triggerEvent('form', 'reset')
    assert.strictEqual(name.value, 'Grace')
    assert.deepEqual(heard.values, ['Grace'])
    await a11yAudit()
  })

  test("a select shows its value once the value's option renders", async function (assert) {
    class Options {
      @tracked list: { value: string; label: string }[] = []
    }
    const options = new Options()
    await render(
      <template>
        <div data-test-jn="native-select">
          <select aria-label="Country" data-test-jn-part="select" {{nativeValue value="ca"}}>
            {{#each options.list as |choice|}}
              <option value={{choice.value}}>{{choice.label}}</option>
            {{/each}}
          </select>
        </div>
      </template>,
    )
    const picker = new NativeSelectHarness()
    assert.strictEqual(picker.value, '', 'no options yet')

    options.list = [
      { value: 'us', label: 'United States' },
      { value: 'ca', label: 'Canada' },
    ]
    await settled()
    assert.strictEqual(picker.value, 'ca', 'it picks its value once it can')
    assert.strictEqual(picker.selectedText, 'Canada')
    await a11yAudit()
  })

  test('a select with no option for its value keeps the one it shows', async function (assert) {
    await render(
      <template>
        <div data-test-jn="native-select">
          <select aria-label="Size" data-test-jn-part="select" {{nativeValue value="xl"}}>
            <option value="s">Small</option>
            <option value="m">Medium</option>
          </select>
        </div>
      </template>,
    )
    assert.strictEqual(new NativeSelectHarness().value, 's', 'not a blank select')
    await a11yAudit()
  })

  test('a file input is never given a value it cannot take', async function (assert) {
    const state = new State('C:\\fakepath\\photo.png')
    await render(
      <template>
        <input
          aria-label="Photo"
          type="file"
          data-test-jn="input"
          {{nativeValue value=state.value}}
        />
      </template>,
    )
    const photo = new InputHarness()
    assert.strictEqual(photo.value, '', 'browsers allow only clearing it; nothing threw')
    state.value = ''
    await settled()
    await rerender()
    assert.strictEqual(photo.value, '')
    await a11yAudit()
  })
})
