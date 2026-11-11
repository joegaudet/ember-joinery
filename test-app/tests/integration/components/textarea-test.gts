import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { render, rerender, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Textarea, asTextarea, textareaAttributes, textareaClasses } from '@ember-joinery/ember'
import { TextareaHarness, tab } from '@ember-joinery/test-support'

const px = (value: string) => Number.parseFloat(value)

module('Integration | components | textarea', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a native textarea with upstream classes and data attributes', async function (assert) {
    await render(<template><Textarea placeholder="Type your message here." /></template>)
    const harness = new TextareaHarness()
    assert
      .dom(harness.element)
      .hasTagName('textarea')
      .hasClass('jn-textarea')
      .hasAttribute('data-slot', 'textarea')
      .doesNotHaveAttribute('data-test-jn-name')
    assert.strictEqual(harness.value, '')
    assert.strictEqual(harness.placeholder, 'Type your message here.')
    assert.strictEqual(harness.label, 'Type your message here.')
    await a11yAudit()
  })

  test('its style sheet sizes it, and it grows with its text', async function (assert) {
    await render(
      <template>
        <Textarea @name="message" aria-label="Message" />
        <Textarea @name="invalid" aria-label="Invalid" aria-invalid="true" />
        <Textarea @name="disabled" aria-label="Disabled" disabled />
      </template>,
    )
    const message = new TextareaHarness('message')
    const style = getComputedStyle(message.element)
    assert.strictEqual(style.minHeight, '64px', 'min-h-16')
    assert.strictEqual(style.display, 'flex')
    assert.strictEqual(style.boxSizing, 'border-box')
    assert.strictEqual(style.borderTopWidth, '1px')
    assert.strictEqual(style.borderTopLeftRadius, '10px', "rounded-lg: the theme's --radius")
    assert.strictEqual(style.paddingTop, '8px', 'py-2')
    assert.strictEqual(style.paddingLeft, '10px', 'px-2.5')
    assert.strictEqual(style.fontSize, '14px', 'md:text-sm, at this width')
    assert.strictEqual(style.resize, 'vertical', 'it resizes only up and down, as preflight')
    assert.strictEqual(style.outlineStyle, 'none')

    const empty = px(style.height)
    await message.fillIn('One\nTwo\nThree\nFour\nFive\nSix')
    assert.ok(px(getComputedStyle(message.element).height) > empty, 'field-sizing-content')

    const invalid = getComputedStyle(new TextareaHarness('invalid').element)
    assert.notStrictEqual(invalid.borderTopColor, style.borderTopColor, 'aria-invalid: its border')
    assert.notStrictEqual(invalid.boxShadow, 'none', 'and a ring')
    const disabled = getComputedStyle(new TextareaHarness('disabled').element)
    assert.strictEqual(disabled.opacity, '0.5', 'disabled:opacity-50')
    assert.strictEqual(disabled.cursor, 'not-allowed')
    await a11yAudit()
  })

  test('uncontrolled from @defaultValue, or controlled with @value', async function (assert) {
    class State {
      @tracked message = 'Hello'
    }
    const state = new State()
    const heard: string[] = []
    const setMessage = (value: string) => {
      heard.push(value)
      state.message = value.slice(0, 10)
    }
    await render(
      <template>
        <Textarea @name="own" @defaultValue="Draft" aria-label="Draft" />
        <Textarea
          @name="controlled"
          @value={{state.message}}
          @onValueChange={{setMessage}}
          aria-label="Message"
        />
      </template>,
    )
    const own = new TextareaHarness('own')
    assert.strictEqual(own.value, 'Draft')
    await own.fillIn('Second draft')
    assert.strictEqual(own.value, 'Second draft', 'it keeps its own value')

    const controlled = new TextareaHarness('controlled')
    assert.strictEqual(controlled.value, 'Hello')
    await controlled.fillIn('Hello, how are you?')
    assert.deepEqual(heard, ['Hello, how are you?'])
    assert.strictEqual(controlled.value, 'Hello, how', 'it shows what the caller kept')
    state.message = ''
    await settled()
    assert.strictEqual(controlled.value, '', 'and follows @value')
    await a11yAudit()
  })

  test('attributes, listeners and the keyboard', async function (assert) {
    let inputs = 0
    const count = () => inputs++
    await render(
      <template>
        <Textarea
          @name="bio"
          name="bio"
          rows="4"
          class="mine"
          required
          aria-label="Bio"
          {{on "input" count}}
        />
        <Textarea @name="off" aria-label="Off" disabled />
        <Textarea @name="last" aria-label="Last" readonly />
      </template>,
    )
    const bio = new TextareaHarness('bio')
    assert.dom(bio.element).hasAttribute('name', 'bio').hasAttribute('rows', '4').hasClass('mine')
    assert.true(bio.isRequired)
    await bio.focus()
    await bio.typeIn('Hi')
    assert.strictEqual(bio.value, 'Hi')
    assert.strictEqual(inputs, 2, 'one input event per key, to the caller’s listener too')

    await tab()
    assert.true(new TextareaHarness('last').isFocused, 'Tab skips the disabled one')
    assert.true(new TextareaHarness('last').isReadOnly)
    assert.true(new TextareaHarness('off').isDisabled)
    await a11yAudit()
  })

  test('the asTextarea modifier makes your own textarea one, the same as the component', async function (assert) {
    await render(
      <template>
        <Textarea @name="x" aria-label="x" data-case="component" />
        <textarea aria-label="x" data-case="modifier" {{asTextarea name="x"}}></textarea>
      </template>,
    )
    const [component] = document.querySelectorAll('[data-case="component"]')
    const [modifier] = document.querySelectorAll('[data-case="modifier"]')
    assert.deepEqual(rendering(component!), rendering(modifier!))
    assert.deepEqual([...component!.classList], textareaClasses().split(' '))
    for (const [name, value] of Object.entries(textareaAttributes({ name: 'x' }))) {
      assert.strictEqual(component!.getAttribute(name), value ?? null, name)
    }
    assert.strictEqual(
      getComputedStyle(TextareaHarness.findAll('x')[1]!.element).minHeight,
      '64px',
      'styled as a textarea',
    )
    await rerender()
    await a11yAudit()
  })

  test('RTL: it reads right to left, from the nearest dir', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Textarea
            @name="rtl"
            aria-label="التعليقات"
            placeholder="تعليقاتك تساعدنا على التحسين..."
          />
        </DirectionProvider>
      </template>,
    )
    const rtl = new TextareaHarness('rtl')
    assert.strictEqual(getComputedStyle(rtl.element).direction, 'rtl')
    assert.strictEqual(rtl.label, 'التعليقات')
    await a11yAudit()
  })

  test('the harness reads its name, description and state through ARIA', async function (assert) {
    await render(
      <template>
        <label for="message-input">Message</label>
        <Textarea @name="message" id="message-input" aria-describedby="message-help" />
        <p id="message-help">Enter your message below.</p>
        <Textarea @name="invalid" aria-label="Invalid" aria-invalid="true" />
      </template>,
    )
    const message = new TextareaHarness('message')
    assert.strictEqual(message.label, 'Message')
    assert.strictEqual(message.description, 'Enter your message below.')
    assert.false(message.isInvalid)
    assert.true(new TextareaHarness('invalid').isInvalid)
    await message.focus()
    assert.true(message.isFocused)
    await message.blur()
    assert.false(message.isFocused)
    assert.throws(() => new TextareaHarness('missing').element, /no textarea "missing" found/)
    await a11yAudit()
  })
})
