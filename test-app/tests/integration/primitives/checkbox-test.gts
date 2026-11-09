import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Checkbox, type CheckedState } from '@ember-joinery/primitives/checkbox'
import { CheckboxHarness, pressKey, tab } from '@ember-joinery/test-support'

module('Integration | primitives | checkbox', function (hooks) {
  setupRenderingTest(hooks)

  test('it is a button with the checkbox role, aria-checked and data-state', async function (assert) {
    await render(
      <template>
        <Checkbox @name="terms" aria-label="Accept terms" as |c|>
          <c.Indicator>✓</c.Indicator>
          <span data-test-state>{{if c.isChecked "on" "off"}}</span>
        </Checkbox>
      </template>,
    )
    const terms = new CheckboxHarness('terms')
    assert
      .dom(terms.element)
      .hasTagName('button')
      .hasAttribute('type', 'button')
      .hasAttribute('role', 'checkbox')
      .hasAttribute('aria-checked', 'false')
      .hasAttribute('data-state', 'unchecked')
      .hasAttribute('value', 'on')
      .doesNotHaveAttribute('aria-required')
      .doesNotHaveAttribute('data-disabled')
    assert.strictEqual(terms.state, 'unchecked')
    assert.strictEqual(terms.indicator, null, 'the mark renders only while checked')
    assert.strictEqual(terms.label, 'Accept terms')
    assert.dom('[data-test-state]').hasText('off', 'it yields its state')
    assert.strictEqual(terms.input, null, 'outside a form, no hidden input')
    await a11yAudit()
  })

  test('uncontrolled: a click toggles it from @defaultChecked, and @onCheckedChange hears it', async function (assert) {
    const changes: CheckedState[] = []
    const changed = (checked: CheckedState) => changes.push(checked)
    await render(
      <template>
        <Checkbox
          @name="terms"
          @defaultChecked={{true}}
          @onCheckedChange={{changed}}
          aria-label="Accept terms"
          as |c|
        >
          <c.Indicator>✓</c.Indicator>
        </Checkbox>
      </template>,
    )
    const terms = new CheckboxHarness('terms')
    assert.true(terms.isChecked)
    assert.dom(terms.indicator).hasAttribute('data-state', 'checked').hasText('✓')

    await terms.click()
    assert.false(terms.isChecked)
    assert.strictEqual(terms.indicator, null)
    await terms.click()
    assert.true(terms.isChecked)
    assert.deepEqual(changes, [false, true])
    await a11yAudit()
  })

  test('controlled: @checked decides, and a click only asks for the change', async function (assert) {
    class State {
      @tracked checked: CheckedState = false
      @tracked accept = true
    }
    const state = new State()
    const asked: CheckedState[] = []
    const change = (checked: CheckedState) => {
      asked.push(checked)
      if (state.accept) state.checked = checked
    }
    await render(
      <template>
        <Checkbox
          @name="terms"
          @checked={{state.checked}}
          @onCheckedChange={{change}}
          aria-label="Accept terms"
        />
      </template>,
    )
    const terms = new CheckboxHarness('terms')
    await terms.click()
    assert.true(terms.isChecked, 'the owner took the change')

    state.accept = false
    await terms.click()
    assert.true(terms.isChecked, 'the owner refused it, so it stays checked')
    assert.deepEqual(asked, [true, false])

    state.checked = false
    await settled()
    assert.false(terms.isChecked, 'and it follows @checked')
    await a11yAudit()
  })

  test('indeterminate: aria-checked is mixed, the mark shows, and a click checks it', async function (assert) {
    class State {
      @tracked checked: CheckedState = 'indeterminate'
    }
    const state = new State()
    const change = (checked: CheckedState) => (state.checked = checked)
    await render(
      <template>
        <Checkbox
          @name="all"
          @checked={{state.checked}}
          @onCheckedChange={{change}}
          aria-label="Select all"
          as |c|
        >
          <c.Indicator>{{if c.isIndeterminate "–" "✓"}}</c.Indicator>
        </Checkbox>
      </template>,
    )
    const all = new CheckboxHarness('all')
    assert.dom(all.element).hasAttribute('aria-checked', 'mixed')
    assert.dom(all.element).hasAttribute('data-state', 'indeterminate')
    assert.true(all.isIndeterminate)
    assert.false(all.isChecked)
    assert.dom(all.indicator).hasAttribute('data-state', 'indeterminate').hasText('–')

    await all.click()
    assert.strictEqual(state.checked, true, 'indeterminate becomes checked, as in Radix')
    assert.dom(all.indicator).hasText('✓')

    await all.uncheck()
    assert.strictEqual(all.state, 'unchecked')
    state.checked = 'indeterminate'
    await settled()
    await all.uncheck()
    assert.strictEqual(all.state, 'unchecked', 'uncheck() clicks twice from indeterminate')
    await a11yAudit()
  })

  test('keyboard: it is in the tab order, Space toggles it (a native button) and Enter does not', async function (assert) {
    await render(
      <template>
        <button type="button" id="before">Before</button>
        <Checkbox @name="terms" aria-label="Accept terms" />
        <Checkbox @name="off" @disabled={{true}} aria-label="Unavailable" />
      </template>,
    )
    const terms = new CheckboxHarness('terms')
    await click('#before')
    await tab()
    assert.true(terms.isFocused, 'Tab reaches it')
    assert.ok(
      terms.element instanceof HTMLButtonElement,
      'a native <button>: the browser clicks it on Space, which toggles it (APG checkbox)',
    )
    assert.true(await pressKey('Enter'), 'Enter is cancelled, so the button never clicks')
    assert.false(terms.isChecked)

    await tab()
    assert.false(new CheckboxHarness('off').isFocused, 'a disabled checkbox is passed over')
    await a11yAudit()
  })

  test('disabled: it ignores clicks and says so', async function (assert) {
    await render(
      <template>
        <Checkbox @name="off" @disabled={{true}} @defaultChecked={{true}} aria-label="Off" as |c|>
          <c.Indicator>✓</c.Indicator>
        </Checkbox>
      </template>,
    )
    const off = new CheckboxHarness('off')
    assert.true(off.isDisabled)
    assert.dom(off.element).hasAttribute('data-disabled', '')
    assert.dom(off.indicator).hasAttribute('data-disabled', '')
    await click(off.element).catch(() => undefined)
    assert.true(off.isChecked, 'unchanged')
    await a11yAudit()
  })

  test("a listener of the caller's can cancel the toggle", async function (assert) {
    const cancel = (event: Event) => event.preventDefault()
    await render(
      <template>
        <Checkbox @name="terms" aria-label="Accept terms" {{on "click" cancel}} />
      </template>,
    )
    const terms = new CheckboxHarness('terms')
    await terms.click()
    assert.false(terms.isChecked)
    await a11yAudit()
  })

  test('a label tied to it by for, or around it, names it and toggles it', async function (assert) {
    await render(
      <template>
        <Checkbox @name="terms" id="terms" />
        <label for="terms">Accept terms and conditions</label>
        <label>
          <Checkbox @name="news" />
          Send me the newsletter
        </label>
      </template>,
    )
    const terms = new CheckboxHarness('terms')
    assert.strictEqual(terms.label, 'Accept terms and conditions')
    await click('label[for="terms"]')
    assert.true(terms.isChecked, 'a click on the label clicks the checkbox')

    const news = new CheckboxHarness('news')
    assert.strictEqual(news.label, 'Send me the newsletter')
    await click(news.element.parentElement!)
    assert.true(news.isChecked)
    await a11yAudit()
  })

  test('in a form: a hidden checkbox submits it, repeats name, value and form, and a reset restores it', async function (assert) {
    class State {
      @tracked name = 'terms'
    }
    const state = new State()
    let changes = 0
    const counted = () => changes++
    await render(
      <template>
        <form id="signup" {{on "change" counted}}>
          <Checkbox @name="terms" name={{state.name}} @required={{true}} aria-label="Terms" />
          <Checkbox
            @name="news"
            name="news"
            value="yes"
            @defaultChecked={{true}}
            aria-label="News"
          />
        </form>
        <Checkbox @name="outside" name="outside" form="signup" aria-label="Outside" />
      </template>,
    )

    const formElement = document.querySelector<HTMLFormElement>('#signup')!
    const terms = new CheckboxHarness('terms')
    const news = new CheckboxHarness('news')
    const outside = new CheckboxHarness('outside')

    assert.true(terms.isRequired)
    assert.dom(terms.input).hasAttribute('type', 'checkbox').hasAttribute('name', 'terms')
    assert.dom(terms.input).hasAttribute('aria-hidden', 'true').hasAttribute('tabindex', '-1')
    assert.true(terms.input!.required)
    assert.false(formElement.checkValidity(), 'a required checkbox blocks the form until checked')
    assert.strictEqual(getComputedStyle(terms.input!).opacity, '0', 'unseen')
    assert.strictEqual(getComputedStyle(terms.input!).pointerEvents, 'none')
    assert.dom(news.input).hasAttribute('value', 'yes')
    assert.dom(outside.input).hasAttribute('form', 'signup', 'form="…" reaches outside it')

    await terms.click()
    await outside.click()
    assert.true(formElement.checkValidity())
    assert.deepEqual(
      [...new FormData(formElement).entries()],
      [
        ['terms', 'on'],
        ['news', 'yes'],
        ['outside', 'on'],
      ],
    )
    assert.strictEqual(changes, 1, 'the form heard a change from the checkbox inside it')

    state.name = 'accept'
    await settled()
    assert.dom(terms.input).hasAttribute('name', 'accept', 'it follows the name')

    formElement.reset()
    await settled()
    assert.false(terms.isChecked, 'a reset puts it back to its first state')
    assert.true(news.isChecked)
    assert.deepEqual([...new FormData(formElement).entries()], [['news', 'yes']])
    await a11yAudit()
  })

  test('@as renders another tag', async function (assert) {
    await render(
      <template>
        <Checkbox @as="span" @name="terms" tabindex="0" aria-label="Accept terms" />
      </template>,
    )
    const terms = new CheckboxHarness('terms')
    assert.dom(terms.element).hasTagName('span').hasAttribute('role', 'checkbox')
    await terms.click()
    assert.true(terms.isChecked)
    await a11yAudit()
  })
})
