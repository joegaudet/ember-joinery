import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { render, rerender, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Input, asInput, inputAttributes, inputClasses } from '@ember-joinery/ember'
import { InputHarness, tab } from '@ember-joinery/test-support'

class State {
  @tracked value = ''
}

module('Integration | components | input', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a native input with upstream classes and data attributes', async function (assert) {
    await render(<template><Input placeholder="Enter text" /></template>)
    const harness = new InputHarness()
    assert
      .dom(harness.element)
      .hasTagName('input')
      .hasClass('jn-input')
      .hasAttribute('data-slot', 'input')
      .hasAttribute('placeholder', 'Enter text')
      .doesNotHaveAttribute('type', 'it leaves type to the caller, as upstream')
      .doesNotHaveAttribute('data-test-jn-name')
    assert.strictEqual(harness.type, 'text', 'so it is a text input')
    assert.strictEqual(harness.value, '')
    assert.strictEqual(harness.placeholder, 'Enter text')
    assert.strictEqual(harness.label, 'Enter text', 'with nothing else, the placeholder names it')
    await a11yAudit()
  })

  test('its style sheet sizes and colours it, without Tailwind', async function (assert) {
    await render(
      <template>
        <Input @name="plain" aria-label="Plain" placeholder="Plain" />
        <Input @name="invalid" aria-label="Invalid" aria-invalid="true" />
        <Input @name="disabled" aria-label="Disabled" disabled />
      </template>,
    )
    const plain = new InputHarness('plain')
    const style = getComputedStyle(plain.element)
    assert.strictEqual(style.height, '32px', 'h-8, border included')
    assert.strictEqual(style.boxSizing, 'border-box')
    assert.strictEqual(style.borderTopWidth, '1px')
    assert.strictEqual(style.borderTopLeftRadius, '10px', "rounded-lg: the theme's --radius")
    assert.strictEqual(style.paddingLeft, '10px', 'px-2.5')
    assert.strictEqual(style.paddingTop, '4px', 'py-1')
    assert.strictEqual(style.fontSize, '14px', 'md:text-sm, at this width')
    assert.strictEqual(
      style.fontFamily,
      getComputedStyle(document.body).fontFamily,
      "it takes the page's font, as preflight gives upstream's",
    )
    assert.strictEqual(style.backgroundColor, 'rgba(0, 0, 0, 0)', 'bg-transparent')
    assert.strictEqual(
      style.width,
      getComputedStyle(plain.element.parentElement!).width,
      'w-full: as wide as its container',
    )
    const placeholder = getComputedStyle(plain.element, '::placeholder')
    assert.strictEqual(placeholder.opacity, '1', 'a placeholder at full opacity, as preflight')
    assert.notStrictEqual(placeholder.color, style.color, 'in the muted colour')

    const invalid = getComputedStyle(new InputHarness('invalid').element)
    assert.notStrictEqual(invalid.borderTopColor, style.borderTopColor, 'aria-invalid: its border')
    assert.notStrictEqual(invalid.boxShadow, 'none', 'and a ring')

    const disabled = getComputedStyle(new InputHarness('disabled').element)
    assert.strictEqual(disabled.opacity, '0.5', 'disabled:opacity-50')
    assert.strictEqual(disabled.cursor, 'not-allowed')
    assert.strictEqual(disabled.pointerEvents, 'none')
    await a11yAudit()
  })

  test('focus shows the ring, and dark mode tints it', async function (assert) {
    await render(
      <template>
        <Input @name="light" aria-label="Light" />
        <div class="dark"><Input @name="dark" aria-label="Dark" /></div>
      </template>,
    )
    const light = new InputHarness('light')
    const before = getComputedStyle(light.element).borderTopColor
    await light.focus()
    const focused = getComputedStyle(light.element)
    assert.notStrictEqual(focused.borderTopColor, before, 'focus-visible:border-ring')
    assert.notStrictEqual(focused.boxShadow, 'none', 'focus-visible:ring-3')
    assert.strictEqual(focused.outlineStyle, 'none', 'outline-none: the ring replaces it')

    const dark = getComputedStyle(new InputHarness('dark').element)
    assert.notStrictEqual(dark.backgroundColor, 'rgba(0, 0, 0, 0)', 'dark:bg-input/30')
    await a11yAudit()
  })

  test('a file input styles its button, and the harness chooses files', async function (assert) {
    await render(<template><Input @name="picture" type="file" aria-label="Picture" /></template>)
    const picture = new InputHarness('picture')
    assert.strictEqual(picture.type, 'file')
    const button = getComputedStyle(picture.element, '::file-selector-button')
    assert.strictEqual(button.height, '24px', 'file:h-6')
    assert.strictEqual(button.fontSize, '14px', 'file:text-sm')
    assert.strictEqual(button.fontWeight, '500', 'file:font-medium')
    assert.strictEqual(button.borderTopWidth, '0px', 'file:border-0')
    assert.strictEqual(button.backgroundColor, 'rgba(0, 0, 0, 0)', 'file:bg-transparent')
    assert.strictEqual(button.display, 'inline-flex', 'file:inline-flex')

    await picture.chooseFiles([new File(['x'], 'photo.png', { type: 'image/png' })])
    assert.deepEqual(picture.fileNames, ['photo.png'])
    await a11yAudit()
  })

  test('uncontrolled, it keeps its own value, from @defaultValue', async function (assert) {
    const heard: string[] = []
    const record = (value: string) => void heard.push(value)
    await render(
      <template>
        <Input @name="name" @defaultValue="Ada" @onValueChange={{record}} aria-label="Name" />
      </template>,
    )
    const name = new InputHarness('name')
    assert.strictEqual(name.value, 'Ada')
    await name.fillIn('Grace')
    assert.strictEqual(name.value, 'Grace')
    await name.clear()
    assert.strictEqual(name.value, '')
    assert.deepEqual(heard, ['Grace', ''], '@onValueChange hears each change')
    await a11yAudit()
  })

  test('controlled, it shows @value, and @onValueChange decides', async function (assert) {
    const state = new State()
    state.value = 'ada'
    const heard: string[] = []
    const setUsername = (value: string) => {
      heard.push(value)
      state.value = value.toLowerCase().replace(/\s+/g, '')
    }
    const refuse = (value: string) => void heard.push(value)
    await render(
      <template>
        <Input
          @name="username"
          @value={{state.value}}
          @onValueChange={{setUsername}}
          aria-label="Username"
        />
        <Input @name="locked" @value="locked" @onValueChange={{refuse}} aria-label="Locked" />
      </template>,
    )
    const username = new InputHarness('username')
    await username.fillIn('Grace Hopper')
    assert.strictEqual(state.value, 'gracehopper')
    assert.strictEqual(username.value, 'gracehopper', 'it shows what the caller made of it')

    state.value = 'lin'
    await settled()
    assert.strictEqual(username.value, 'lin', 'and follows @value')

    const locked = new InputHarness('locked')
    await locked.fillIn('changed')
    assert.strictEqual(locked.value, 'locked', 'a change the caller refuses is undone')
    assert.deepEqual(heard, ['Grace Hopper', 'changed'])
    await a11yAudit()
  })

  test('it takes attributes and listeners on the input', async function (assert) {
    let inputs = 0
    const count = () => inputs++
    await render(
      <template>
        <Input
          @name="email"
          type="email"
          name="email"
          class="mine"
          required
          readonly
          placeholder="name@example.com"
          aria-label="Email"
          {{on "input" count}}
        />
        <Input @name="search" type="search" aria-label="Search" {{on "input" count}} />
      </template>,
    )
    const email = new InputHarness('email')
    assert
      .dom(email.element)
      .hasAttribute('type', 'email')
      .hasAttribute('name', 'email')
      .hasClass('mine')
      .hasClass('jn-input')
    assert.strictEqual(email.type, 'email')
    assert.true(email.isRequired)
    assert.true(email.isReadOnly)

    await new InputHarness('search').fillIn('shadcn')
    assert.strictEqual(inputs, 1, 'the caller’s listener runs too')
    await a11yAudit()
  })

  test('keyboard: it is in the tab order, and typing fills it in', async function (assert) {
    await render(
      <template>
        <Input @name="first" aria-label="First" />
        <Input @name="off" aria-label="Off" disabled />
        <Input @name="last" aria-label="Last" />
      </template>,
    )
    const first = new InputHarness('first')
    const last = new InputHarness('last')
    await first.focus()
    assert.true(first.isFocused)
    await first.typeIn('Ada')
    assert.strictEqual(first.value, 'Ada', 'each key types a character')

    await tab()
    assert.true(last.isFocused, 'Tab skips the disabled input')
    assert.true(new InputHarness('off').isDisabled)
    await last.blur()
    assert.false(last.isFocused)
    await a11yAudit()
  })

  test('the asInput modifier makes your own input one, the same as the component', async function (assert) {
    await render(
      <template>
        <Input @name="x" aria-label="x" data-case="component" />
        <input aria-label="x" data-case="modifier" {{asInput name="x"}} />
        <Input aria-label="y" data-case="component" />
        <input aria-label="y" data-case="modifier" {{asInput}} />
      </template>,
    )
    const components = [...document.querySelectorAll('[data-case="component"]')]
    const modifiers = [...document.querySelectorAll('[data-case="modifier"]')]
    components.forEach((component, index) => {
      assert.deepEqual(rendering(component), rendering(modifiers[index]!), `${index}: the same`)
    })
    assert.deepEqual([...components[0]!.classList], inputClasses().split(' '))
    for (const [name, value] of Object.entries(inputAttributes({ name: 'x' }))) {
      assert.strictEqual(components[0]!.getAttribute(name), value ?? null, name)
    }

    const mine = InputHarness.findAll('x')[1]!
    assert.strictEqual(getComputedStyle(mine.element).height, '32px', 'styled as an input')
    await mine.fillIn('typed')
    assert.strictEqual(mine.value, 'typed', 'the harness drives it')
    await rerender()
    await a11yAudit()
  })

  test('RTL: it reads right to left, from the nearest dir', async function (assert) {
    await render(
      <template>
        <Input @name="ltr" aria-label="API key" placeholder="sk-..." />
        <DirectionProvider @dir="rtl">
          <Input @name="rtl" aria-label="مفتاح API" placeholder="sk-..." />
        </DirectionProvider>
      </template>,
    )
    const ltr = getComputedStyle(new InputHarness('ltr').element)
    const rtl = getComputedStyle(new InputHarness('rtl').element)
    assert.strictEqual(ltr.direction, 'ltr')
    assert.strictEqual(rtl.direction, 'rtl', 'its text starts on the right')
    assert.strictEqual(rtl.paddingRight, ltr.paddingLeft, 'with the same padding at its start')
    await a11yAudit()
  })

  test('the harness reads its name, description and state through ARIA', async function (assert) {
    await render(
      <template>
        <label for="email-input">Email</label>
        <Input @name="for" id="email-input" aria-describedby="email-help email-error" />
        <p id="email-help">We'll never share it.</p>
        <p id="email-error">Enter a valid email.</p>
        <label>Wrapped <Input @name="wrapped" /></label>
        <span id="caption">From a caption</span>
        <Input @name="labelled" aria-labelledby="caption" aria-label="Ignored" />
        <Input @name="invalid" aria-label="Invalid" aria-invalid="true" />
        <Input @name="empty" aria-label="Empty" aria-invalid="" />
        <Input @name="valid" aria-label="Valid" aria-invalid="false" />
      </template>,
    )
    const email = new InputHarness('for')
    assert.strictEqual(email.label, 'Email', 'its <label for>')
    assert.strictEqual(email.description, "We'll never share it. Enter a valid email.")
    assert.strictEqual(new InputHarness('wrapped').label, 'Wrapped', 'a label around it')
    assert.strictEqual(
      new InputHarness('labelled').label,
      'From a caption',
      'aria-labelledby first',
    )
    assert.strictEqual(new InputHarness('wrapped').description, '', 'none without one')
    assert.true(new InputHarness('invalid').isInvalid)
    assert.false(new InputHarness('empty').isInvalid, 'an empty aria-invalid is false')
    assert.false(new InputHarness('valid').isInvalid)
    assert.throws(() => new InputHarness('missing').element, /no input "missing" found/)
    await a11yAudit()
  })
})
