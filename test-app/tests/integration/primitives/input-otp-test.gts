import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  InputOTP,
  INPUT_OTP_LABEL,
  REGEXP_ONLY_CHARS,
  REGEXP_ONLY_DIGITS,
  REGEXP_ONLY_DIGITS_AND_CHARS,
} from '@ember-joinery/primitives/input-otp'
import { InputOTPHarness, fillOTP, tab } from '@ember-joinery/test-support'

module('Integration | primitives | input-otp', function (hooks) {
  setupRenderingTest(hooks)

  test('one invisible native input over the slots it yields', async function (assert) {
    await render(
      <template>
        <InputOTP @maxLength={{6}} @name="code" @containerClass="mine" as |otp|>
          {{#each otp.slots as |slot|}}
            <otp.Slot @index={{slot.index}} class="slot" />
          {{/each}}
        </InputOTP>
      </template>,
    )
    const otp = new InputOTPHarness('code')
    assert
      .dom(otp.element)
      .hasTagName('div')
      .hasClass('mine')
      .hasAttribute('data-input-otp-container')
    assert
      .dom(otp.input)
      .hasAttribute('autocomplete', 'one-time-code')
      .hasAttribute('inputmode', 'numeric')
      .hasAttribute('maxlength', '6')
      .hasAttribute('data-input-otp')
      .hasAttribute('data-input-otp-placeholder-shown', 'true')
      .doesNotHaveAttribute('pattern')
    assert.strictEqual(otp.slots.length, 6)
    assert.deepEqual(otp.chars, ['', '', '', '', '', ''])
    assert.dom(otp.slot(0)).hasClass('slot').hasAttribute('data-active', 'false')
    assert.strictEqual(otp.label, INPUT_OTP_LABEL, 'it names itself when nothing else does')
    assert.strictEqual(otp.maxLength, 6)

    const input = getComputedStyle(otp.input)
    assert.strictEqual(input.position, 'absolute')
    assert.strictEqual(input.color, 'rgba(0, 0, 0, 0)', 'its text is transparent')
    assert.strictEqual(input.caretColor, 'rgba(0, 0, 0, 0)')
    assert.strictEqual(getComputedStyle(otp.element).pointerEvents, 'none')
    assert.strictEqual(input.pointerEvents, 'all', 'only the input takes the pointer')
    const box = otp.element.getBoundingClientRect()
    const over = otp.input.getBoundingClientRect()
    assert.deepEqual([over.left, over.top], [box.left, box.top], 'it lies over the slots')
    assert.strictEqual(
      otp.element.style.getPropertyValue('--root-height'),
      `${otp.input.clientHeight}px`,
    )
    await a11yAudit()
  })

  test('typing fills the slots, and the active slot follows the caret', async function (assert) {
    const completed: string[] = []
    const changes: string[] = []
    const complete = (value: string) => completed.push(value)
    const change = (value: string) => changes.push(value)
    await render(
      <template>
        <InputOTP @maxLength={{4}} @onComplete={{complete}} @onValueChange={{change}} as |otp|>
          {{#each otp.slots as |slot|}}
            <otp.Slot @index={{slot.index}} as |s|>
              {{s.char}}{{#if s.hasFakeCaret}}<span data-test-jn-part="caret">|</span>{{/if}}
            </otp.Slot>
          {{/each}}
          <p data-test-state>{{otp.value}}
            {{if otp.isComplete "complete"}}
            {{if otp.isFocused "focused"}}</p>
        </InputOTP>
      </template>,
    )
    const otp = new InputOTPHarness()
    assert.strictEqual(otp.activeIndex, null, 'no slot is active without focus')

    await otp.focus()
    assert.strictEqual(otp.activeIndex, 0)
    assert.true(otp.hasCaret(0), 'an empty active slot draws the caret')
    assert.dom('[data-test-state]').hasText('focused')

    await otp.typeIn('12')
    assert.deepEqual(otp.chars, ['1', '2', '|', ''])
    assert.strictEqual(otp.activeIndex, 2)
    assert.deepEqual(changes, ['1', '12'])
    assert.dom(otp.input).doesNotHaveAttribute('data-input-otp-placeholder-shown')

    await otp.typeIn('34')
    assert.strictEqual(otp.value, '1234')
    assert.true(otp.isComplete)
    assert.deepEqual(otp.activeIndexes, [3], 'complete, the last character is selected')
    assert.false(otp.hasCaret(3))
    assert.deepEqual(completed, ['1234'], '@onComplete, once')
    assert.dom('[data-test-state]').hasText('1234 complete focused')

    await otp.typeIn('9')
    assert.strictEqual(otp.value, '1239', 'typing replaces the selected character')
    assert.deepEqual(completed, ['1234'], 'still complete: no second call')

    await otp.blur()
    assert.strictEqual(otp.activeIndex, null)
    await a11yAudit()
  })

  test('Backspace, Delete, the arrows, Home and End work on one character at a time', async function (assert) {
    await render(
      <template>
        <InputOTP @maxLength={{6}} @defaultValue="123456" aria-label="Code" as |otp|>
          {{#each otp.slots as |slot|}}<otp.Slot @index={{slot.index}} />{{/each}}
        </InputOTP>
      </template>,
    )
    const otp = new InputOTPHarness()
    await otp.focus()
    assert.deepEqual(otp.activeIndexes, [5], 'focus selects the last character')

    await otp.press('Backspace')
    assert.strictEqual(otp.value, '12345')
    assert.strictEqual(otp.activeIndex, 5, 'the caret waits where the next character goes')
    await otp.press('Backspace')
    assert.strictEqual(otp.value, '1234')
    assert.strictEqual(otp.activeIndex, 4)

    await otp.press('ArrowLeft')
    assert.deepEqual(otp.activeIndexes, [3], 'left selects the character before')
    await otp.press('ArrowLeft')
    assert.deepEqual(otp.activeIndexes, [2])
    await otp.typeIn('9')
    assert.strictEqual(otp.value, '1294', 'typing over it replaces it')
    assert.deepEqual(otp.activeIndexes, [3], 'and selects the next one')

    await otp.press('ArrowRight')
    assert.strictEqual(otp.activeIndex, 4, 'past the last character, it waits for a new one')
    await otp.press('Home')
    assert.deepEqual(otp.activeIndexes, [0], 'Home selects the first')
    await otp.press('Delete')
    assert.strictEqual(otp.value, '294')
    await otp.press('End')
    assert.strictEqual(otp.activeIndex, 3)

    await otp.clickSlot(1)
    assert.deepEqual(otp.activeIndexes, [1], 'clicking a slot selects its character')
    await a11yAudit()
  })

  test('uncontrolled from @defaultValue, or controlled with @value', async function (assert) {
    class State {
      @tracked code = '12'
    }
    const state = new State()
    const heard: string[] = []
    const setCode = (value: string) => {
      heard.push(value)
      state.code = value.toUpperCase()
    }
    await render(
      <template>
        <InputOTP @name="own" @maxLength={{4}} @defaultValue="98" aria-label="Own" as |otp|>
          {{#each otp.slots as |slot|}}<otp.Slot @index={{slot.index}} />{{/each}}
        </InputOTP>
        <InputOTP
          @name="theirs"
          @maxLength={{4}}
          @value={{state.code}}
          @onValueChange={{setCode}}
          inputmode="text"
          aria-label="Theirs"
          as |otp|
        >
          {{#each otp.slots as |slot|}}<otp.Slot @index={{slot.index}} />{{/each}}
        </InputOTP>
      </template>,
    )
    const own = new InputOTPHarness('own')
    assert.strictEqual(own.value, '98')
    await own.typeIn('7')
    assert.deepEqual(own.chars, ['9', '8', '7', ''])

    const theirs = new InputOTPHarness('theirs')
    assert.deepEqual(theirs.chars, ['1', '2', '', ''])
    await theirs.typeIn('ab')
    assert.deepEqual(heard, ['12a', '12Ab'], 'it tells @onValueChange each change')
    assert.strictEqual(theirs.value, '12AB', 'and shows the code the caller keeps')
    state.code = ''
    await settled()
    assert.deepEqual(theirs.chars, ['', '', '', ''], 'it follows @value')
    assert.dom(theirs.input).hasAttribute('inputmode', 'text', 'its attributes win')
    await a11yAudit()
  })

  test('@onComplete when the caller completes the code too', async function (assert) {
    class State {
      @tracked code = ''
    }
    const state = new State()
    const completed: string[] = []
    const complete = (value: string) => completed.push(value)
    await render(
      <template>
        <InputOTP
          @maxLength={{3}}
          @value={{state.code}}
          @onComplete={{complete}}
          aria-label="Code"
          as |otp|
        >
          {{#each otp.slots as |slot|}}<otp.Slot @index={{slot.index}} />{{/each}}
        </InputOTP>
      </template>,
    )
    state.code = '123'
    await settled()
    assert.deepEqual(completed, ['123'])
    assert.deepEqual(new InputOTPHarness().chars, ['1', '2', '3'])
    await a11yAudit()
  })

  test('@pattern refuses what it does not match', async function (assert) {
    const inputs: string[] = []
    const heard = (event: Event) => inputs.push((event.target as HTMLInputElement).value)
    await render(
      <template>
        <InputOTP
          @name="digits"
          @maxLength={{4}}
          @pattern={{REGEXP_ONLY_DIGITS}}
          aria-label="Digits"
          {{on "input" heard}}
          as |otp|
        >
          {{#each otp.slots as |slot|}}<otp.Slot @index={{slot.index}} />{{/each}}
        </InputOTP>
        <InputOTP
          @name="mixed"
          @maxLength={{4}}
          @pattern={{REGEXP_ONLY_DIGITS_AND_CHARS}}
          aria-label="Mixed"
          as |otp|
        >
          {{#each otp.slots as |slot|}}<otp.Slot @index={{slot.index}} />{{/each}}
        </InputOTP>
      </template>,
    )
    const digits = new InputOTPHarness('digits')
    assert.dom(digits.input).hasAttribute('pattern', REGEXP_ONLY_DIGITS)
    await digits.typeIn('1a2')
    assert.strictEqual(digits.value, '12', 'the letter is refused')
    assert.deepEqual(inputs, ['1', '12'], 'and nothing else hears it')
    await digits.fillIn('12-4')
    assert.strictEqual(digits.value, '12')

    const mixed = new InputOTPHarness('mixed')
    await mixed.typeIn('a1B2')
    assert.strictEqual(mixed.value, 'a1B2')
    assert.ok(new RegExp(REGEXP_ONLY_CHARS).test('abc'))
    assert.notOk(new RegExp(REGEXP_ONLY_CHARS).test('ab1'))
    await a11yAudit()
  })

  test('a paste goes into the selection, through @pasteTransformer, cut to its length', async function (assert) {
    const inputs: string[] = []
    const heard = (event: Event) => inputs.push((event as InputEvent).inputType)
    const strip = (pasted: string) => pasted.replace(/-/g, '')
    await render(
      <template>
        <InputOTP
          @name="plain"
          @maxLength={{6}}
          @pattern={{REGEXP_ONLY_DIGITS}}
          aria-label="Plain"
          {{on "input" heard}}
          as |otp|
        >
          {{#each otp.slots as |slot|}}<otp.Slot @index={{slot.index}} />{{/each}}
        </InputOTP>
        <InputOTP
          @name="dashes"
          @maxLength={{6}}
          @pattern={{REGEXP_ONLY_DIGITS}}
          @pasteTransformer={{strip}}
          aria-label="Dashes"
          as |otp|
        >
          {{#each otp.slots as |slot|}}<otp.Slot @index={{slot.index}} />{{/each}}
        </InputOTP>
      </template>,
    )
    const plain = new InputOTPHarness('plain')
    await plain.typeIn('1')
    await plain.paste('23456789')
    assert.strictEqual(plain.value, '123456', 'after the caret, cut to @maxLength')
    assert.deepEqual(plain.activeIndexes, [5])
    assert.deepEqual(inputs, ['insertText', 'insertFromPaste'], 'an input event, as a paste fires')
    await plain.paste('7')
    assert.strictEqual(plain.value, '123457', 'over the selected character')
    await plain.paste('a')
    assert.strictEqual(plain.value, '123457', 'a paste the pattern refuses changes nothing')

    const dashes = new InputOTPHarness('dashes')
    await dashes.paste('123-456')
    assert.strictEqual(dashes.value, '123456', '@pasteTransformer strips the dash')
    assert.true(dashes.isComplete)
    await a11yAudit()
  })

  test("the browser's autofill puts the whole code in at once", async function (assert) {
    const completed: string[] = []
    const complete = (value: string) => completed.push(value)
    await render(
      <template>
        <InputOTP
          @maxLength={{6}}
          @pattern={{REGEXP_ONLY_DIGITS}}
          @onComplete={{complete}}
          aria-label="Code"
          as |otp|
        >
          {{#each otp.slots as |slot|}}<otp.Slot @index={{slot.index}} />{{/each}}
        </InputOTP>
      </template>,
    )
    const otp = new InputOTPHarness()
    await otp.autofill('1234567')
    assert.deepEqual(otp.chars, ['1', '2', '3', '4', '5', '6'], 'cut to @maxLength')
    assert.deepEqual(completed, ['123456'])
    assert.false(otp.isFocused, 'it leaves focus alone')
    await a11yAudit()
  })

  test('it names itself only when nothing else does, and @label names it always', async function (assert) {
    await render(
      <template>
        <label for="labelled">Verification code</label>
        <InputOTP @name="labelled" @maxLength={{4}} id="labelled" as |otp|>
          {{#each otp.slots as |slot|}}<otp.Slot @index={{slot.index}} />{{/each}}
        </InputOTP>
        <InputOTP @name="aria" @maxLength={{4}} aria-label="PIN" as |otp|>
          {{#each otp.slots as |slot|}}<otp.Slot @index={{slot.index}} />{{/each}}
        </InputOTP>
        <InputOTP @name="translated" @maxLength={{4}} @label="رمز التحقق" as |otp|>
          {{#each otp.slots as |slot|}}<otp.Slot @index={{slot.index}} />{{/each}}
        </InputOTP>
        <p id="hint">Sent to your phone.</p>
        <InputOTP @name="described" @maxLength={{4}} aria-describedby="hint" as |otp|>
          {{#each otp.slots as |slot|}}<otp.Slot @index={{slot.index}} />{{/each}}
        </InputOTP>
      </template>,
    )
    const labelled = new InputOTPHarness('labelled')
    assert.strictEqual(labelled.label, 'Verification code')
    assert.dom(labelled.input).doesNotHaveAttribute('aria-label')
    await click('label[for="labelled"]')
    assert.true(labelled.isFocused, 'its label focuses it')
    assert.strictEqual(new InputOTPHarness('aria').label, 'PIN')
    assert.strictEqual(new InputOTPHarness('translated').label, 'رمز التحقق')
    const described = new InputOTPHarness('described')
    assert.strictEqual(described.label, 'One-time password')
    assert.strictEqual(described.description, 'Sent to your phone.')
    await a11yAudit()
  })

  test('@placeholder shows a character a slot while the code is empty', async function (assert) {
    await render(
      <template>
        <InputOTP @maxLength={{3}} @placeholder="○○○" aria-label="Code" as |otp|>
          {{#each otp.slots as |slot|}}
            <otp.Slot @index={{slot.index}} as |s|>{{if s.char s.char s.placeholderChar}}</otp.Slot>
          {{/each}}
        </InputOTP>
      </template>,
    )
    const otp = new InputOTPHarness()
    assert
      .dom(otp.input)
      .hasAttribute('aria-placeholder', '○○○')
      .doesNotHaveAttribute('placeholder')
    assert.deepEqual(otp.chars, ['○', '○', '○'])
    await otp.typeIn('1')
    assert.deepEqual(otp.chars, ['1', '', ''], 'gone once there is a character')
    await a11yAudit()
  })

  test('in a form: its name submits the code, reset puts it back, and @autoSubmit', async function (assert) {
    const submitted: string[] = []
    const submit = (event: SubmitEvent) => {
      event.preventDefault()
      const data = new FormData(event.target as HTMLFormElement)
      submitted.push(String(data.get('code')))
    }
    await render(
      <template>
        <form data-test-form {{on "submit" submit}}>
          <InputOTP
            @name="otp"
            @maxLength={{4}}
            @defaultValue="12"
            @pattern={{REGEXP_ONLY_DIGITS}}
            @autoSubmit={{true}}
            name="code"
            required
            aria-label="Code"
            as |otp|
          >
            {{#each otp.slots as |slot|}}<otp.Slot @index={{slot.index}} />{{/each}}
          </InputOTP>
          <button type="reset">Reset</button>
        </form>
      </template>,
    )
    const otp = new InputOTPHarness('otp')
    assert.true(otp.isRequired)
    await otp.typeIn('3')
    assert.deepEqual(submitted, [], 'not yet complete')
    await otp.typeIn('4')
    assert.deepEqual(submitted, ['1234'], 'complete, it submits the form')

    await click('button[type="reset"]')
    assert.strictEqual(otp.value, '12', 'a reset puts back the code it started with')
    assert.deepEqual(otp.chars, ['1', '2', '', ''])

    await fillOTP('', '[data-test-form]')
    const verify = document.querySelector<HTMLFormElement>('[data-test-form]')!
    assert.false(verify.checkValidity(), 'required: an empty code is invalid')
    await fillOTP('5678', '[data-test-form]')
    assert.strictEqual(otp.value, '5678', 'fillOTP, as in ember-primitives')
    await a11yAudit()
  })

  test('disabled: no focus, no hover', async function (assert) {
    await render(
      <template>
        <button type="button">Before</button>
        <InputOTP @maxLength={{4}} @defaultValue="1234" disabled aria-label="Code" as |otp|>
          {{#each otp.slots as |slot|}}<otp.Slot @index={{slot.index}} />{{/each}}
          <span data-test-hover>{{if otp.isHovering "hover"}}</span>
        </InputOTP>
        <button type="button">After</button>
      </template>,
    )
    const otp = new InputOTPHarness()
    assert.true(otp.isDisabled)
    await click('button')
    await tab()
    assert.dom('button:last-of-type').isFocused('Tab skips it')
    otp.input.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }))
    await settled()
    assert.dom('[data-test-hover]').hasNoText()
    await a11yAudit()
  })

  test('hovering, and reaching past the slots for a password manager', async function (assert) {
    await render(
      <template>
        <div style="width: 200px">
          <InputOTP @name="reach" @maxLength={{4}} aria-label="Reach" as |otp|>
            {{#each otp.slots as |slot|}}<otp.Slot @index={{slot.index}} />{{/each}}
            <span data-test-hover>{{if otp.isHovering "hover"}}</span>
          </InputOTP>
          <InputOTP
            @name="still"
            @maxLength={{4}}
            @pushPasswordManagerStrategy="none"
            @textAlign="center"
            aria-label="Still"
            as |otp|
          >
            {{#each otp.slots as |slot|}}<otp.Slot @index={{slot.index}} />{{/each}}
          </InputOTP>
        </div>
      </template>,
    )
    const reach = new InputOTPHarness('reach')
    reach.input.dispatchEvent(new MouseEvent('mouseover', { bubbles: true }))
    await settled()
    assert.dom('[data-test-hover]').hasText('hover')
    reach.input.dispatchEvent(new MouseEvent('mouseleave'))
    await settled()
    assert.dom('[data-test-hover]').hasNoText()

    // Computed widths: the test container is scaled, and these are layout sizes.
    const width = (element: Element) => Number.parseFloat(getComputedStyle(element).width)
    assert.strictEqual(width(reach.input), width(reach.element), 'as wide as the slots')
    await reach.focus()
    assert.strictEqual(width(reach.input), width(reach.element) + 40, 'focused, 40px wider')
    assert.strictEqual(reach.input.style.clipPath, 'inset(0px 40px 0px 0px)', 'clipped there')

    const still = new InputOTPHarness('still')
    await still.focus()
    assert.strictEqual(
      width(still.input),
      width(still.element),
      "@pushPasswordManagerStrategy='none' doesn't",
    )
    assert.strictEqual(getComputedStyle(still.input).textAlign, 'center')
    await a11yAudit()
  })

  test('without a block for its slots, each shows its character', async function (assert) {
    await render(
      <template>
        <InputOTP @maxLength={{2}} @defaultValue="42" aria-label="Code" as |otp|>
          <otp.Slot @index={{0}} />
          <otp.Slot @index={{1}} />
          <otp.Slot @index={{2}} />
        </InputOTP>
      </template>,
    )
    const otp = new InputOTPHarness()
    assert.deepEqual(otp.chars, ['4', '2', ''])
    assert.dom(otp.slot(2)).doesNotHaveAttribute('data-active', 'a slot past the end')
    assert.true(otp.isComplete)
    await a11yAudit()
  })
})
