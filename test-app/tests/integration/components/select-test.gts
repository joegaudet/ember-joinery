import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Field, FieldLabel, Select } from '@ember-joinery/ember'
import { SelectHarness, pressKey } from '@ember-joinery/test-support'

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

const rect = (element: Element) => element.getBoundingClientRect()

/** The colour a token resolves to, as computed styles report colours. */
function token(name: string): string {
  const probe = document.createElement('div')
  probe.style.setProperty('color', `var(${name})`)
  document.body.append(probe)
  const color = getComputedStyle(probe).color
  probe.remove()
  return color
}

/** Ends the content's entry animation, so its computed style is the resting one. */
function finishAnimations(element: Element) {
  for (const animation of element.getAnimations({ subtree: true })) animation.finish()
}

type Assert = Parameters<Parameters<typeof test>[1]>[0]

function near(assert: Assert, actual: number, expected: number, message: string) {
  assert.true(Math.abs(actual - expected) <= 1, `${message} (${actual} ≈ ${expected})`)
}

const fruits = [
  { value: 'apple', label: 'Apple' },
  { value: 'banana', label: 'Banana' },
  { value: 'blueberry', label: 'Blueberry' },
]

const many = Array.from({ length: 40 }, (_, index) => ({
  value: `item-${index}`,
  label: `Item ${index}`,
}))

module('Integration | components | select', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders upstream’s classes and slots, and the placeholder while nothing is chosen', async function (assert) {
    await render(
      <template>
        <Select @name="fruit" as |s|>
          <s.Trigger class="w-48" aria-label="Fruit">
            <s.Value @placeholder="Select a fruit" />
          </s.Trigger>
          <s.Content>
            <s.Group>
              <s.Label>Fruits</s.Label>
              {{#each fruits as |fruit|}}
                <s.Item @value={{fruit.value}}>{{fruit.label}}</s.Item>
              {{/each}}
            </s.Group>
          </s.Content>
        </Select>
      </template>,
    )
    const select = new SelectHarness('fruit')
    assert
      .dom(select.trigger)
      .hasClass('jn-select-trigger')
      .hasClass('w-48', 'your class adds to it')
      .hasAttribute('data-slot', 'select-trigger')
      .hasAttribute('data-size', 'default')
      .hasAttribute('role', 'combobox')
      .hasAttribute('data-placeholder', '')
    assert.dom('[data-slot="select-value"]', select.trigger).hasText('Select a fruit')
    assert
      .dom('[data-test-jn-part="icon"]', select.trigger)
      .hasClass('jn-select-trigger-icon')
      .hasAttribute('aria-hidden', 'true')
    assert.strictEqual(select.valueText, 'Select a fruit')

    await select.open()
    const content = select.content!
    assert
      .dom(content)
      .hasClass('jn-select-content')
      .hasClass('jn-menu-target')
      .doesNotHaveClass('jn-menu-translucent', 'opaque, as ui.shadcn.com shows it')
      .hasAttribute('data-slot', 'select-content')
      .hasAttribute('data-align-trigger', 'true')
    assert.dom('.jn-select-viewport', content).hasAttribute('data-position', 'item-aligned')
    assert.dom('[data-slot="select-group"]', content).hasClass('jn-select-group')
    assert.dom('[data-slot="select-label"]', content).hasClass('jn-select-label').hasText('Fruits')
    assert
      .dom(select.option('apple'))
      .hasClass('jn-select-item')
      .hasAttribute('data-slot', 'select-item')
    assert.dom('.jn-select-item-indicator', select.option('apple')).exists()
    assert.deepEqual(select.groups, ['Fruits'])
    await a11yAudit()
  })

  test('its style sheet sizes and colours the trigger, without Tailwind', async function (assert) {
    await render(
      <template>
        <Select as |s|>
          <s.Trigger aria-label="Fruit"><s.Value @placeholder="Select a fruit" /></s.Trigger>
          <s.Content><s.Item @value="apple">Apple</s.Item></s.Content>
        </Select>
        <Select @defaultValue="apple" as |s|>
          <s.Trigger @size="sm" aria-label="Small"><s.Value /></s.Trigger>
          <s.Content><s.Item @value="apple">Apple</s.Item></s.Content>
        </Select>
      </template>,
    )
    const [select, small] = SelectHarness.findAll()
    const style = getComputedStyle(select!.trigger)
    assert.strictEqual(style.height, '32px', 'h-8')
    assert.strictEqual(style.display, 'flex')
    assert.strictEqual(style.borderTopWidth, '1px', 'border')
    assert.strictEqual(style.borderTopColor, token('--input'), 'border-input')
    assert.strictEqual(style.borderTopLeftRadius, '10px', 'rounded-lg')
    assert.strictEqual(style.paddingInlineStart, '10px', 'ps-2.5')
    assert.strictEqual(style.paddingInlineEnd, '8px', 'pe-2')
    assert.strictEqual(style.columnGap, '6px', 'gap-1.5')
    assert.strictEqual(px(style.fontSize), 14, 'text-sm')
    assert.strictEqual(style.whiteSpace, 'nowrap')
    assert.strictEqual(style.color, token('--muted-foreground'), 'the placeholder is muted')
    const icon = select!.trigger.querySelector('svg')!
    assert.strictEqual(getComputedStyle(icon).width, '16px', 'size-4')
    assert.strictEqual(getComputedStyle(icon).color, token('--muted-foreground'))
    assert.strictEqual(getComputedStyle(small!.trigger).height, '28px', 'data-[size=sm]:h-7')
    assert.notStrictEqual(
      getComputedStyle(small!.trigger).color,
      token('--muted-foreground'),
      'a chosen value isn’t muted',
    )
    await a11yAudit()
  })

  test('item-aligned: the chosen option sits over the value, and the options are styled', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 240px; left: 300px">
          <Select @defaultValue="banana" as |s|>
            <s.Trigger class="w-48" aria-label="Fruit"><s.Value /></s.Trigger>
            <s.Content>
              <s.Group>
                <s.Label>Fruits</s.Label>
                {{#each fruits as |fruit|}}
                  <s.Item @value={{fruit.value}}>{{fruit.label}}</s.Item>
                {{/each}}
              </s.Group>
              <s.Separator />
              <s.Group><s.Item @value="carrot">Carrot</s.Item></s.Group>
            </s.Content>
          </Select>
        </div>
      </template>,
    )
    const select = new SelectHarness()
    await select.open()
    const content = select.content!
    finishAnimations(content)
    assert.strictEqual(select.position, 'item-aligned')
    const value = rect(select.queryPart('value')!)
    const bananaText = rect(
      select.option('banana').querySelector('[data-test-jn-part="option-text"]')!,
    )
    near(assert, bananaText.left, value.left, 'the option’s text starts where the value does')
    near(
      assert,
      bananaText.top + bananaText.height / 2,
      value.top + value.height / 2,
      'on the same line',
    )

    const style = getComputedStyle(content)
    assert.strictEqual(style.minWidth, '144px', 'min-w-36')
    assert.strictEqual(style.borderTopLeftRadius, '10px', 'rounded-lg')
    assert.strictEqual(style.backgroundColor, token('--popover'), 'bg-popover')
    assert.notStrictEqual(style.boxShadow, 'none', 'shadow-md and its ring')
    assert.strictEqual(style.animationName, 'none', 'no animation over the trigger')

    const item = getComputedStyle(select.option('apple'))
    assert.strictEqual(item.paddingTop, '4px', 'py-1')
    assert.strictEqual(item.paddingInlineStart, '6px', 'ps-1.5')
    assert.strictEqual(item.paddingInlineEnd, '32px', 'pe-8')
    assert.strictEqual(item.borderTopLeftRadius, '8px', 'rounded-md')
    assert.strictEqual(px(item.fontSize), 14, 'text-sm')
    const focused = getComputedStyle(select.option('banana'))
    assert.strictEqual(focused.backgroundColor, token('--accent'), 'focus:bg-accent')
    const indicator = select.option('banana').querySelector('.jn-select-item-indicator')!
    assert.strictEqual(getComputedStyle(indicator).position, 'absolute')
    assert.strictEqual(getComputedStyle(indicator).width, '16px', 'size-4')
    assert.dom('svg', indicator).exists('a check mark on the chosen option')
    assert
      .dom('svg', select.option('apple').querySelector('.jn-select-item-indicator')!)
      .doesNotExist()

    const label = getComputedStyle(content.querySelector('[data-slot="select-label"]')!)
    assert.strictEqual(px(label.fontSize), 12, 'text-xs')
    assert.strictEqual(label.color, token('--muted-foreground'))
    const group = getComputedStyle(content.querySelector('[data-slot="select-group"]')!)
    assert.strictEqual(group.paddingTop, '4px', 'p-1')
    const separator = getComputedStyle(content.querySelector('[data-slot="select-separator"]')!)
    assert.strictEqual(separator.height, '1px', 'h-px')
    assert.strictEqual(separator.backgroundColor, token('--border'), 'bg-border')
    await a11yAudit()
  })

  test('popper: below the trigger, centred, 4px off, the viewport as wide as the trigger', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 120px; left: 300px">
          <Select as |s|>
            <s.Trigger style="width: 192px" aria-label="Fruit">
              <s.Value @placeholder="Pick" />
            </s.Trigger>
            <s.Content @position="popper">
              {{#each fruits as |fruit|}}
                <s.Item @value={{fruit.value}}>{{fruit.label}}</s.Item>
              {{/each}}
            </s.Content>
          </Select>
        </div>
      </template>,
    )
    const select = new SelectHarness()
    await select.open()
    const content = select.content!
    finishAnimations(content)
    assert.strictEqual(select.position, 'popper')
    assert
      .dom(content)
      .hasAttribute('data-align-trigger', 'false')
      .hasAttribute('data-side', 'bottom')
    assert.dom('.jn-select-viewport', content).hasAttribute('data-position', 'popper')
    const t = rect(select.trigger)
    const c = rect(content)
    near(assert, c.top, t.bottom + 4, 'below, translate-y-1 (4px) off it')
    near(assert, c.left + c.width / 2, t.left + t.width / 2, 'centred, as upstream’s align')
    const viewport = content.querySelector('.jn-select-viewport')!
    assert.true(
      rect(viewport).width >= t.width - 1,
      `min-w-(--radix-select-trigger-width) (${rect(viewport).width} ≥ ${t.width})`,
    )
    await a11yAudit()
  })

  test('in a Field, the field sizes the trigger, as upstream’s does with no root element', async function (assert) {
    await render(
      <template>
        <div style="width: 320px">
          <Field @name="vertical">
            <FieldLabel for="vertical-fruit">Fruit</FieldLabel>
            <Select @name="vertical" as |s|>
              <s.Trigger id="vertical-fruit"><s.Value @placeholder="Fruit" /></s.Trigger>
              <s.Content><s.Item @value="apple">Apple</s.Item></s.Content>
            </Select>
          </Field>
          <Field @name="horizontal" @orientation="horizontal">
            <FieldLabel for="horizontal-fruit">Fruit</FieldLabel>
            <Select @name="horizontal" as |s|>
              <s.Trigger id="horizontal-fruit"><s.Value @placeholder="Fruit" /></s.Trigger>
              <s.Content><s.Item @value="apple">Apple</s.Item></s.Content>
            </Select>
          </Field>
        </div>
      </template>,
    )
    const vertical = new SelectHarness('vertical').trigger
    assert.strictEqual(vertical.offsetWidth, 320, 'a vertical field stretches it (*:w-full)')
    const horizontal = new SelectHarness('horizontal').trigger
    assert.true(horizontal.offsetWidth < 160, 'a horizontal field leaves its w-fit')
    await a11yAudit()
  })

  test('aria-invalid on the trigger draws the destructive border', async function (assert) {
    await render(
      <template>
        <Select as |s|>
          <s.Trigger aria-label="Fruit" aria-invalid="true"><s.Value
              @placeholder="Pick"
            /></s.Trigger>
          <s.Content><s.Item @value="apple">Apple</s.Item></s.Content>
        </Select>
      </template>,
    )
    const select = new SelectHarness()
    assert.true(select.isInvalid)
    assert.strictEqual(getComputedStyle(select.trigger).borderTopColor, token('--destructive'))
    await a11yAudit()
  })

  test('disabled: the trigger is half-faded and can’t open; a disabled option is too', async function (assert) {
    await render(
      <template>
        <Select @disabled={{true}} @name="off" as |s|>
          <s.Trigger aria-label="Fruit"><s.Value @placeholder="Pick" /></s.Trigger>
          <s.Content><s.Item @value="apple">Apple</s.Item></s.Content>
        </Select>
        <Select @name="on" as |s|>
          <s.Trigger aria-label="Fruit"><s.Value @placeholder="Pick" /></s.Trigger>
          <s.Content>
            <s.Item @value="apple">Apple</s.Item>
            <s.Item @value="grapes" @disabled={{true}}>Grapes</s.Item>
          </s.Content>
        </Select>
      </template>,
    )
    const off = new SelectHarness('off')
    assert.true(off.isDisabled)
    assert.strictEqual(getComputedStyle(off.trigger).opacity, '0.5', 'disabled:opacity-50')
    const on = new SelectHarness('on')
    await on.open()
    assert.true(on.isOptionDisabled('grapes'))
    assert.strictEqual(getComputedStyle(on.option('grapes')).opacity, '0.5')
    assert.strictEqual(getComputedStyle(on.option('grapes')).pointerEvents, 'none')
    await a11yAudit()
  })

  test('right to left: the padding and the check mark flip, and the text lines up at the right', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 240px; left: 300px">
          <DirectionProvider @dir="rtl">
            <Select @defaultValue="banana" as |s|>
              <s.Trigger class="w-32" aria-label="فاكهة"><s.Value /></s.Trigger>
              <s.Content>
                <s.Item @value="apple">تفاح</s.Item>
                <s.Item @value="banana">موز</s.Item>
              </s.Content>
            </Select>
          </DirectionProvider>
        </div>
      </template>,
    )
    const select = new SelectHarness()
    const trigger = getComputedStyle(select.trigger)
    assert.strictEqual(trigger.paddingRight, '10px', 'ps-2.5 is on the right')
    assert.strictEqual(trigger.paddingLeft, '8px')
    await select.open()
    const option = select.option('banana')
    const indicator = option.querySelector('.jn-select-item-indicator')!
    assert.true(
      rect(indicator).left < rect(option).left + rect(option).width / 2,
      'the check is at the left',
    )
    const value = rect(select.queryPart('value')!)
    const text = rect(option.querySelector('[data-test-jn-part="option-text"]')!)
    near(assert, text.right, value.right, 'the option’s text ends where the value does')
    await pressKey('ArrowUp')
    assert.dom(select.option('apple')).isFocused()
    await a11yAudit()
  })

  test('many options: the content fits the viewport, and the scroll buttons show their chevrons', async function (assert) {
    await render(
      <template>
        <div style="position: fixed; top: 20px; left: 300px">
          <Select @defaultValue="item-0" as |s|>
            <s.Trigger class="w-48" aria-label="Item"><s.Value /></s.Trigger>
            <s.Content>
              {{#each many as |item|}}<s.Item @value={{item.value}}>{{item.label}}</s.Item>{{/each}}
            </s.Content>
          </Select>
        </div>
      </template>,
    )
    const select = new SelectHarness()
    await select.open()
    await settled()
    assert.false(select.canScrollUp)
    assert.true(select.canScrollDown, 'more below')
    const down = select.part('scroll-down-button')
    assert
      .dom(down)
      .hasClass('jn-select-scroll-down-button')
      .hasAttribute('data-slot', 'select-scroll-down-button')
    assert.dom('svg', down).exists('a chevron')
    assert.strictEqual(getComputedStyle(down.querySelector('svg')!).width, '16px')
    assert.true(
      rect(select.content!).bottom <= window.innerHeight,
      'the content stays inside the viewport',
    )
    await pressKey('End')
    await settled()
    assert.dom(select.option('item-39')).isFocused()
    assert.true(select.canScrollUp, 'now there are options above')
    await a11yAudit()
  })

  test('controlled: the value it is given, and each choice the user makes', async function (assert) {
    class State {
      @tracked value = 'apple'
      choices: string[] = []
      choose = (value: string) => {
        this.choices.push(value)
        this.value = value
      }
    }
    const state = new State()
    await render(
      <template>
        <Select @value={{state.value}} @onValueChange={{state.choose}} as |s|>
          <s.Trigger aria-label="Fruit"><s.Value /></s.Trigger>
          <s.Content>
            {{#each fruits as |fruit|}}<s.Item
                @value={{fruit.value}}
              >{{fruit.label}}</s.Item>{{/each}}
          </s.Content>
        </Select>
      </template>,
    )
    const select = new SelectHarness()
    assert.strictEqual(select.valueText, 'Apple')
    await select.select('blueberry')
    assert.deepEqual(state.choices, ['blueberry'])
    assert.strictEqual(select.valueText, 'Blueberry')
    await select.openWithKeyboard('ArrowDown')
    assert.dom(select.option('blueberry')).isFocused()
    await select.typeahead('a')
    assert.dom(select.option('apple')).isFocused()
    await pressKey('Enter')
    assert.deepEqual(state.choices, ['blueberry', 'apple'])
    await a11yAudit()
  })
})
