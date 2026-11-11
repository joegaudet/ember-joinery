import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ChevronsUpDown } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { NativeSelect } from '@ember-joinery/ember'
import { IconHarness, NativeSelectHarness, tab } from '@ember-joinery/test-support'

const px = (value: string) => Number.parseFloat(value)

module('Integration | components | native-select', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a native select in a wrapper, with upstream classes and data attributes', async function (assert) {
    await render(
      <template>
        <NativeSelect aria-label="Status" as |s|>
          <s.Option @value="">Select status</s.Option>
          <s.Option @value="todo">Todo</s.Option>
          <s.Option @value="done">Done</s.Option>
        </NativeSelect>
      </template>,
    )
    const harness = new NativeSelectHarness()
    assert
      .dom(harness.element)
      .hasTagName('div')
      .hasClass('jn-native-select-wrapper')
      .hasClass('group/native-select')
      .hasAttribute('data-slot', 'native-select-wrapper')
      .hasAttribute('data-size', 'default')
    assert
      .dom(harness.control)
      .hasTagName('select')
      .hasClass('jn-native-select')
      .hasAttribute('data-slot', 'native-select')
      .hasAttribute('data-size', 'default')
      .hasAttribute('aria-label', 'Status', 'attributes go on the select')
    assert
      .dom(harness.icon)
      .hasClass('jn-native-select-icon')
      .hasClass('jn-size-own')
      .hasAttribute('data-slot', 'native-select-icon')
      .hasAttribute('aria-hidden', 'true')
    assert.true(harness.icon.classList.contains('lucide'), "lucide's chevron-down")
    const option = harness.control.options[1]!
    assert
      .dom(option)
      .hasClass('jn-native-select-option')
      .hasAttribute('data-slot', 'native-select-option')
      .hasAttribute('value', 'todo')
      .hasAttribute('data-test-jn-value', 'todo')
    assert.deepEqual(harness.options, ['', 'todo', 'done'])
    assert.deepEqual(harness.optionTexts, ['Select status', 'Todo', 'Done'])
    assert.strictEqual(harness.value, '', 'the first option, as a native select')
    assert.strictEqual(harness.selectedText, 'Select status')
    assert.strictEqual(harness.size, 'default')
    assert.strictEqual(harness.label, 'Status')
    await a11yAudit()
  })

  test('its style sheet sizes it, and draws the chevron at its end', async function (assert) {
    await render(
      <template>
        <NativeSelect @name="default" aria-label="Default" as |s|>
          <s.Option @value="a">A fairly long option</s.Option>
        </NativeSelect>
        <NativeSelect @name="sm" @size="sm" aria-label="Small" as |s|>
          <s.Option @value="a">A</s.Option>
        </NativeSelect>
        <NativeSelect @name="invalid" aria-label="Invalid" aria-invalid="true" as |s|>
          <s.Option @value="a">A</s.Option>
        </NativeSelect>
      </template>,
    )
    const harness = new NativeSelectHarness('default')
    const control = getComputedStyle(harness.control)
    assert.strictEqual(control.height, '32px', 'h-8, border included')
    assert.strictEqual(control.appearance, 'none', "appearance-none: the browser's arrow is gone")
    assert.strictEqual(control.borderTopWidth, '1px')
    assert.strictEqual(control.borderTopLeftRadius, '10px', 'rounded-lg')
    assert.strictEqual(control.paddingLeft, '10px', 'ps-2.5')
    assert.strictEqual(control.paddingRight, '32px', 'pe-8: room for the chevron')
    assert.strictEqual(control.fontSize, '14px', 'text-sm')
    assert.strictEqual(control.backgroundColor, 'rgba(0, 0, 0, 0)', 'bg-transparent')

    const wrapper = getComputedStyle(harness.element)
    assert.strictEqual(wrapper.position, 'relative')
    assert.strictEqual(control.width, wrapper.width, 'w-full in a w-fit wrapper')
    assert.ok(px(wrapper.width) < px(getComputedStyle(document.body).width), 'which fits it')

    const icon = getComputedStyle(harness.icon)
    assert.strictEqual(icon.position, 'absolute')
    assert.strictEqual(icon.width, '16px', 'size-4')
    assert.strictEqual(icon.pointerEvents, 'none', 'a click on it reaches the select')
    assert.strictEqual(icon.right, '10px', 'end-2.5: at the end, on the right')
    const box = harness.element.getBoundingClientRect()
    const chevron = harness.icon.getBoundingClientRect()
    assert.strictEqual(
      Math.round(chevron.top + chevron.height / 2),
      Math.round(box.top + box.height / 2),
      'centred: top-1/2 -translate-y-1/2',
    )

    const small = new NativeSelectHarness('sm')
    assert.strictEqual(small.size, 'sm')
    assert.dom(small.control).hasAttribute('data-size', 'sm')
    assert.strictEqual(getComputedStyle(small.control).height, '28px', 'data-[size=sm]:h-7')

    const invalid = getComputedStyle(new NativeSelectHarness('invalid').control)
    assert.notStrictEqual(
      invalid.borderTopColor,
      control.borderTopColor,
      'aria-invalid: its border',
    )
    assert.notStrictEqual(invalid.boxShadow, 'none', 'and a ring')
    await a11yAudit()
  })

  test('groups, disabled options, and a disabled select', async function (assert) {
    await render(
      <template>
        <NativeSelect @name="department" aria-label="Department" as |s|>
          <s.Option @value="">Select department</s.Option>
          <s.OptGroup label="Engineering">
            <s.Option @value="frontend">Frontend</s.Option>
            <s.Option @value="backend" disabled>Backend</s.Option>
          </s.OptGroup>
          <s.OptGroup label="Sales" disabled>
            <s.Option @value="sales-rep">Sales Rep</s.Option>
          </s.OptGroup>
        </NativeSelect>
        <NativeSelect @name="off" aria-label="Off" disabled as |s|>
          <s.Option @value="">Disabled</s.Option>
        </NativeSelect>
      </template>,
    )
    const department = new NativeSelectHarness('department')
    assert.deepEqual(department.groups, ['Engineering', 'Sales'])
    assert.deepEqual(department.optionsIn('Engineering'), ['frontend', 'backend'])
    assert.dom(department.control.querySelector('optgroup')).hasClass('jn-native-select-optgroup')
    assert.false(department.isOptionDisabled('frontend'))
    assert.true(department.isOptionDisabled('backend'))
    assert.true(department.isOptionDisabled('sales-rep'), 'its group is disabled')

    const off = new NativeSelectHarness('off')
    assert.true(off.isDisabled)
    assert.strictEqual(getComputedStyle(off.element).opacity, '0.5', 'has-[select:disabled]')
    assert.strictEqual(getComputedStyle(off.control).cursor, 'not-allowed')
    await off.select('').then(
      () => assert.notOk(true, 'a disabled select can’t be chosen from'),
      () => assert.ok(true, 'a disabled select can’t be chosen from'),
    )
    await a11yAudit()
  })

  test('uncontrolled from @defaultValue, or controlled with @value', async function (assert) {
    class State {
      @tracked status = 'todo'
    }
    const state = new State()
    const heard: string[] = []
    const setStatus = (value: string) => {
      heard.push(value)
      state.status = value
    }
    await render(
      <template>
        <NativeSelect @name="own" @defaultValue="pear" aria-label="Fruit" as |s|>
          <s.Option @value="apple">Apple</s.Option>
          <s.Option @value="pear">Pear</s.Option>
        </NativeSelect>
        <NativeSelect
          @name="status"
          @value={{state.status}}
          @onValueChange={{setStatus}}
          aria-label="Status"
          as |s|
        >
          <s.Option @value="todo">Todo</s.Option>
          <s.Option @value="done">Done</s.Option>
        </NativeSelect>
      </template>,
    )
    const own = new NativeSelectHarness('own')
    assert.strictEqual(own.value, 'pear', 'it starts from @defaultValue')
    await own.select('apple')
    assert.strictEqual(own.value, 'apple')

    const status = new NativeSelectHarness('status')
    assert.strictEqual(status.value, 'todo')
    await status.select('done')
    assert.deepEqual(heard, ['done'])
    assert.strictEqual(state.status, 'done')
    state.status = 'todo'
    await settled()
    assert.strictEqual(status.value, 'todo', 'it follows @value')
    assert.strictEqual(status.selectedText, 'Todo')
    await a11yAudit()
  })

  test('keyboard: a native select in the tab order, with listeners of your own', async function (assert) {
    let changes = 0
    const count = () => changes++
    await render(
      <template>
        <NativeSelect @name="first" aria-label="First" {{on "change" count}} as |s|>
          <s.Option @value="a">A</s.Option>
          <s.Option @value="b">B</s.Option>
        </NativeSelect>
        <NativeSelect @name="last" aria-label="Last" name="last" required class="mine" as |s|>
          <s.Option @value="a">A</s.Option>
        </NativeSelect>
      </template>,
    )
    const first = new NativeSelectHarness('first')
    assert.ok(
      first.control instanceof HTMLSelectElement,
      "a native <select>: the browser's own keys open it and move through its options",
    )
    await first.focus()
    assert.true(first.isFocused)
    await first.select('b')
    assert.strictEqual(changes, 1, 'the caller’s listener runs')

    await tab()
    const last = new NativeSelectHarness('last')
    assert.true(last.isFocused, 'Tab moves on to the next')
    assert.dom(last.control).hasAttribute('name', 'last').hasClass('mine')
    assert.true(last.isRequired)
    await last.blur()
    assert.false(last.isFocused)
    await a11yAudit()
  })

  test('@icon replaces the chevron, and the parts work as modifiers', async function (assert) {
    await render(
      <template>
        <NativeSelect @icon={{ChevronsUpDown}} aria-label="Sort" as |s|>
          <option value="new" {{s.option value="new"}}>Newest</option>
          <optgroup label="Other" {{s.optGroup}}>
            <option value="old" {{s.option value="old"}}>Oldest</option>
          </optgroup>
        </NativeSelect>
      </template>,
    )
    const harness = new NativeSelectHarness()
    const icon = harness.find(IconHarness)
    assert.true(icon.isDecorative)
    assert.dom(harness.icon).hasClass('jn-native-select-icon')
    assert.notOk(
      harness.icon.querySelector('path')?.getAttribute('d') === 'm6 9 6 6 6-6',
      "it isn't the chevron-down",
    )
    assert.deepEqual(harness.options, ['new', 'old'])
    assert.dom(harness.control.options[0]).hasClass('jn-native-select-option')
    assert.dom(harness.control.options[0]).hasAttribute('data-test-jn-value', 'new')
    assert.deepEqual(harness.groups, ['Other'])
    assert.dom(harness.control.querySelector('optgroup')).hasClass('jn-native-select-optgroup')
    await a11yAudit()
  })

  test('RTL: the chevron and its room move to the left', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <NativeSelect @name="rtl" aria-label="الحالة" as |s|>
            <s.Option @value="">اختر الحالة</s.Option>
            <s.Option @value="todo">مهام</s.Option>
          </NativeSelect>
        </DirectionProvider>
      </template>,
    )
    const rtl = new NativeSelectHarness('rtl')
    const control = getComputedStyle(rtl.control)
    assert.strictEqual(control.direction, 'rtl')
    assert.strictEqual(control.paddingLeft, '32px', 'pe-8, at the end, on the left')
    assert.strictEqual(control.paddingRight, '10px')
    assert.strictEqual(getComputedStyle(rtl.icon).left, '10px', 'end-2.5: at the end, on the left')
    await a11yAudit()
  })

  test('the harness reads its name, description and state through ARIA', async function (assert) {
    await render(
      <template>
        <label for="country">Country</label>
        <NativeSelect @name="country" id="country" aria-describedby="country-help" as |s|>
          <s.Option @value="us">United States</s.Option>
        </NativeSelect>
        <p id="country-help">Where you live.</p>
        <NativeSelect @name="invalid" aria-label="Invalid" aria-invalid="true" as |s|>
          <s.Option @value="">Error state</s.Option>
        </NativeSelect>
      </template>,
    )
    const country = new NativeSelectHarness('country')
    assert.strictEqual(country.label, 'Country')
    assert.strictEqual(country.description, 'Where you live.')
    assert.false(country.isInvalid)
    assert.true(new NativeSelectHarness('invalid').isInvalid)
    assert.throws(() => country.isOptionDisabled('mars'), /no option "mars"/)
    assert.throws(() => new NativeSelectHarness('missing').element, /no native-select "missing"/)
    await a11yAudit()
  })
})
