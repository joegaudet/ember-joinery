import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { finishTransitions, shadowReach } from 'test-app/tests/helpers/shadow'
import { render, rerender, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Asterisk } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { InputOTP, REGEXP_ONLY_DIGITS, REGEXP_ONLY_DIGITS_AND_CHARS } from '@ember-joinery/ember'
import { InputOTPHarness, tab } from '@ember-joinery/test-support'

const px = (value: string) => Number.parseFloat(value)

module('Integration | components | input-otp', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders upstream's slots, groups and separator, with their classes and data attributes", async function (assert) {
    await render(
      <template>
        <InputOTP @maxLength={{6}} @name="code" as |otp|>
          <otp.Group>
            <otp.Slot @index={{0}} />
            <otp.Slot @index={{1}} />
            <otp.Slot @index={{2}} />
          </otp.Group>
          <otp.Separator />
          <otp.Group>
            <otp.Slot @index={{3}} />
            <otp.Slot @index={{4}} />
            <otp.Slot @index={{5}} />
          </otp.Group>
        </InputOTP>
      </template>,
    )
    const otp = new InputOTPHarness('code')
    assert
      .dom(otp.element)
      .hasClass('jn-input-otp-container')
      .doesNotHaveClass('jn-input-otp', "upstream's never resolves its container's class")
    assert
      .dom(otp.input)
      .hasClass('jn-input-otp-input')
      .hasAttribute('data-slot', 'input-otp')
      .hasAttribute('spellcheck', 'false')
      .hasAttribute('autocomplete', 'one-time-code')
      .hasAttribute('maxlength', '6')
    assert.strictEqual(otp.groups.length, 2)
    assert
      .dom(otp.groups[0])
      .hasClass('jn-input-otp-group')
      .hasAttribute('data-slot', 'input-otp-group')
    assert.strictEqual(otp.slots.length, 6)
    assert
      .dom(otp.slot(0))
      .hasClass('jn-input-otp-slot')
      .hasAttribute('data-slot', 'input-otp-slot')
      .hasAttribute('data-active', 'false')
    const [separator] = otp.separators
    assert
      .dom(separator)
      .hasClass('jn-input-otp-separator')
      .hasAttribute('role', 'separator')
      .hasAttribute('data-slot', 'input-otp-separator')
    assert.dom(separator!.querySelector('svg')).hasClass('lucide')
    assert.dom(separator!.querySelector('svg path')).hasAttribute('d', 'M5 12h14', "lucide's minus")
    assert.strictEqual(otp.label, 'One-time password')
    await a11yAudit()
  })

  test('its style sheet draws the slots as one field per group, and the caret', async function (assert) {
    await render(
      <template>
        <InputOTP @maxLength={{4}} as |otp|>
          <otp.Group>
            <otp.Slot @index={{0}} />
            <otp.Slot @index={{1}} />
          </otp.Group>
          <otp.Separator />
          <otp.Group>
            <otp.Slot @index={{2}} />
            <otp.Slot @index={{3}} />
          </otp.Group>
        </InputOTP>
      </template>,
    )
    const otp = new InputOTPHarness()
    const container = getComputedStyle(otp.element)
    assert.strictEqual(container.display, 'flex')
    assert.strictEqual(container.alignItems, 'center')
    assert.strictEqual(container.columnGap, 'normal', "no gap, as upstream's unresolved class")

    const first = getComputedStyle(otp.slot(0))
    const second = getComputedStyle(otp.slot(1))
    assert.strictEqual(first.width, '32px', 'size-8')
    assert.strictEqual(first.height, '32px')
    assert.strictEqual(first.display, 'flex')
    assert.strictEqual(first.fontSize, '14px', 'text-sm')
    assert.strictEqual(first.borderLeftWidth, '1px', 'first:border-s')
    assert.strictEqual(
      first.borderTopLeftRadius,
      '10px',
      "first:rounded-s-lg, the theme's --radius",
    )
    assert.strictEqual(second.borderLeftWidth, '0px', 'the next shares its border')
    assert.strictEqual(second.borderRightWidth, '1px', 'border-e')
    assert.strictEqual(second.borderTopRightRadius, '10px', 'last:rounded-e-lg')
    assert.strictEqual(getComputedStyle(otp.groups[0]!).display, 'flex')
    const icon = otp.separators[0]!.querySelector('svg')!
    assert.strictEqual(getComputedStyle(icon).width, '16px', "the separator's icon is size-4")

    await otp.focus()
    const active = finishTransitions(otp.slot(0))
    assert.dom(otp.slot(0)).hasAttribute('data-active', 'true')
    assert.strictEqual(shadowReach(otp.slot(0)), 3, 'the active slot has a ring: ring-3')
    assert.strictEqual(shadowReach(otp.slot(1)), 0, 'the others none')
    assert.notStrictEqual(active.borderTopColor, second.borderTopColor, 'and the ring colour')
    assert.strictEqual(active.zIndex, '10', 'above its neighbours')
    assert.true(otp.hasCaret(0))
    const line = otp.slot(0).querySelector('.jn-input-otp-caret-line')!
    assert.strictEqual(getComputedStyle(line).width, '1px', 'a 1px caret')
    assert.strictEqual(getComputedStyle(line).height, '16px', 'h-4')
    assert.strictEqual(getComputedStyle(line).animationName, 'caret-blink')
    assert.strictEqual(getComputedStyle(otp.slot(0).firstElementChild!).position, 'absolute')

    await otp.typeIn('1')
    assert.false(otp.hasCaret(0), 'a filled slot has no caret')
    assert.true(otp.hasCaret(1))
    await a11yAudit()
  })

  test('aria-invalid on the slots rings them and their group', async function (assert) {
    await render(
      <template>
        <InputOTP @maxLength={{2}} @defaultValue="00" as |otp|>
          <otp.Group>
            <otp.Slot @index={{0}} aria-invalid="true" />
            <otp.Slot @index={{1}} aria-invalid="true" />
          </otp.Group>
        </InputOTP>
        <InputOTP @name="fine" @maxLength={{2}} @defaultValue="00" as |otp|>
          <otp.Group>
            <otp.Slot @index={{0}} />
            <otp.Slot @index={{1}} />
          </otp.Group>
        </InputOTP>
      </template>,
    )
    const invalid = new InputOTPHarness()
    const fine = new InputOTPHarness('fine')
    assert.true(invalid.isInvalid)
    assert.false(fine.isInvalid)
    assert.notStrictEqual(
      getComputedStyle(invalid.slot(0)).borderTopColor,
      getComputedStyle(fine.slot(0)).borderTopColor,
      'aria-invalid:border-destructive',
    )
    assert.strictEqual(
      shadowReach(invalid.groups[0]!),
      3,
      'its group rings: has-aria-invalid:ring-3',
    )
    assert.strictEqual(shadowReach(fine.groups[0]!), 0)
    await a11yAudit()
  })

  test('disabled dims it and leaves the tab order', async function (assert) {
    await render(
      <template>
        <InputOTP @maxLength={{2}} @defaultValue="12" disabled as |otp|>
          <otp.Group>
            <otp.Slot @index={{0}} />
            <otp.Slot @index={{1}} />
          </otp.Group>
        </InputOTP>
        <button type="button">Next</button>
      </template>,
    )
    const otp = new InputOTPHarness()
    assert.true(otp.isDisabled)
    assert.strictEqual(getComputedStyle(otp.element).opacity, '0.5', 'has-disabled:opacity-50')
    assert.strictEqual(getComputedStyle(otp.input).cursor, 'not-allowed')
    await tab()
    assert.dom('button').isFocused()
    await a11yAudit()
  })

  test('controlled and uncontrolled, with a pattern', async function (assert) {
    class State {
      @tracked code = ''
    }
    const state = new State()
    const setCode = (value: string) => (state.code = value)
    await render(
      <template>
        <InputOTP
          @name="theirs"
          @maxLength={{4}}
          @value={{state.code}}
          @onValueChange={{setCode}}
          @pattern={{REGEXP_ONLY_DIGITS}}
          as |otp|
        >
          <otp.Group>
            <otp.Slot @index={{0}} />
            <otp.Slot @index={{1}} />
            <otp.Slot @index={{2}} />
            <otp.Slot @index={{3}} />
          </otp.Group>
          <p data-test-entered>{{otp.value}}</p>
        </InputOTP>
        <InputOTP
          @name="own"
          @maxLength={{4}}
          @defaultValue="a1"
          @pattern={{REGEXP_ONLY_DIGITS_AND_CHARS}}
          as |otp|
        >
          <otp.Group>
            <otp.Slot @index={{0}} />
            <otp.Slot @index={{1}} />
            <otp.Slot @index={{2}} />
            <otp.Slot @index={{3}} />
          </otp.Group>
        </InputOTP>
      </template>,
    )
    const theirs = new InputOTPHarness('theirs')
    await theirs.typeIn('1x2')
    assert.strictEqual(state.code, '12', 'the pattern refuses the letter')
    assert.dom('[data-test-entered]').hasText('12')
    state.code = '9876'
    await settled()
    assert.deepEqual(theirs.chars, ['9', '8', '7', '6'])

    const own = new InputOTPHarness('own')
    await own.paste('B2')
    assert.deepEqual(own.chars, ['a', '1', 'B', '2'])
    await a11yAudit()
  })

  test('the group and separator modifiers make your own elements those parts', async function (assert) {
    await render(
      <template>
        <InputOTP @maxLength={{2}} as |otp|>
          <otp.Group data-case="component"><otp.Slot @index={{0}} /></otp.Group>
          <section {{otp.group}} data-case="modifier"><otp.Slot @index={{1}} /></section>
          <otp.Separator data-case="separator-component" />
          <div {{otp.separator}} data-case="separator-modifier">·</div>
        </InputOTP>
      </template>,
    )
    const [component] = document.querySelectorAll('[data-case="component"]')
    const [modifier] = document.querySelectorAll('[data-case="modifier"]')
    assert.deepEqual(rendering(component!), rendering(modifier!))
    const [separator] = document.querySelectorAll('[data-case="separator-component"]')
    const [mine] = document.querySelectorAll('[data-case="separator-modifier"]')
    assert.deepEqual(rendering(separator!), rendering(mine!))
    assert.strictEqual(new InputOTPHarness().groups.length, 2)
    await rerender()
    await a11yAudit()
  })

  test('a separator takes an icon of your own', async function (assert) {
    await render(
      <template>
        <InputOTP @maxLength={{2}} as |otp|>
          <otp.Group><otp.Slot @index={{0}} /></otp.Group>
          <otp.Separator @icon={{Asterisk}} />
          <otp.Group><otp.Slot @index={{1}} /></otp.Group>
        </InputOTP>
      </template>,
    )
    const [separator] = new InputOTPHarness().separators
    assert.strictEqual(separator!.querySelectorAll('svg').length, 1)
    assert.strictEqual(separator!.querySelectorAll('svg path').length, 3, "lucide's asterisk")
    await a11yAudit()
  })

  test('RTL: the slots run right to left, and the rounded ends follow', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <InputOTP @maxLength={{3}} @defaultValue="123" @label="رمز التحقق" as |otp|>
            <otp.Group>
              <otp.Slot @index={{0}} />
              <otp.Slot @index={{1}} />
              <otp.Slot @index={{2}} />
            </otp.Group>
          </InputOTP>
        </DirectionProvider>
      </template>,
    )
    const otp = new InputOTPHarness()
    const first = otp.slot(0).getBoundingClientRect()
    const last = otp.slot(2).getBoundingClientRect()
    assert.ok(first.left > last.left, 'the first slot is on the right')
    const style = getComputedStyle(otp.slot(0))
    assert.strictEqual(style.borderTopRightRadius, '10px', 'first:rounded-s-lg, on the right')
    assert.strictEqual(px(style.borderRightWidth), 1, 'first:border-s, on the right')
    assert.strictEqual(otp.label, 'رمز التحقق')
    await a11yAudit()
  })
})
