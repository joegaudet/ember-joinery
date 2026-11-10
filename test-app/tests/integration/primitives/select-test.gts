import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import {
  find,
  focus,
  render,
  rerender,
  settled,
  triggerEvent,
  waitUntil,
} from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Select } from '@ember-joinery/primitives/select'
import { SelectHarness, pressKey, setupAnchorFallback, tab } from '@ember-joinery/test-support'

/** Fixed sizes, so where the content goes can be measured. */
const Styles = <template>
  <style>
    .sel-stage {
      position: fixed;
      top: 240px;
      left: 300px;
    }
    .sel-trigger {
      display: flex;
      width: 160px;
      height: 32px;
      padding: 0 8px;
      border: 0;
    }
    .sel-content {
      background: white;
      padding: 4px;
    }
    .sel-item {
      height: 30px;
      padding: 0 8px;
      display: flex;
      align-items: center;
    }
    .sel-viewport {
      padding: 0;
    }
  </style>
</template>

const fruits = [
  { value: 'apple', label: 'Apple' },
  { value: 'banana', label: 'Banana' },
  { value: 'blueberry', label: 'Blueberry' },
  { value: 'grapes', label: 'Grapes' },
  { value: 'pineapple', label: 'Pineapple' },
]

class State {
  @tracked value = 'banana'
  @tracked open = false
  values: string[] = []
  opens: boolean[] = []
  setValue = (value: string) => {
    this.values.push(value)
    this.value = value
  }
  setOpen = (open: boolean) => {
    this.opens.push(open)
    this.open = open
  }
}

const isGrapes = (value: string) => value === 'grapes'

type Assert = Parameters<Parameters<typeof test>[1]>[0]

const rect = (element: Element) => element.getBoundingClientRect()

function near(assert: Assert, actual: number, expected: number, message: string) {
  assert.true(Math.abs(actual - expected) <= 1, `${message} (${actual} ≈ ${expected})`)
}

module('Integration | primitives | select', function (hooks) {
  setupRenderingTest(hooks)

  test('the trigger is a combobox that shows the placeholder, and the options render off the page while closed', async function (assert) {
    await render(
      <template>
        <Select @name="fruit" as |s|>
          <s.Trigger aria-label="Fruit">
            <s.Value @placeholder="Select a fruit" />
            <s.Icon />
          </s.Trigger>
          <s.Content>
            <s.Viewport>
              {{#each fruits as |fruit|}}
                <s.Item @value={{fruit.value}} as |item|>
                  <item.ItemText>{{fruit.label}}</item.ItemText>
                </s.Item>
              {{/each}}
            </s.Viewport>
          </s.Content>
        </Select>
      </template>,
    )
    const select = new SelectHarness('fruit')
    assert
      .dom(select.trigger)
      .hasTagName('button')
      .hasAttribute('type', 'button')
      .hasAttribute('role', 'combobox')
      .hasAttribute('aria-expanded', 'false')
      .hasAttribute('aria-autocomplete', 'none')
      .hasAttribute('data-state', 'closed')
      .hasAttribute('data-placeholder', '')
      .doesNotHaveAttribute('aria-controls', 'nothing to control while closed')
    assert.strictEqual(select.valueText, 'Select a fruit')
    assert.true(select.isPlaceholder)
    assert.strictEqual(select.value, '')
    assert.strictEqual(select.label, 'Fruit')
    assert.dom('[data-test-jn-part="icon"]').hasText('▼').hasAttribute('aria-hidden', 'true')
    assert.strictEqual(select.content, null, 'no listbox in the page while closed')
    assert.strictEqual(select.nativeSelect, null, 'no native select outside a form')
    await a11yAudit()
  })

  test('uncontrolled: a press opens it, a press on an option chooses it, and focus goes back', async function (assert) {
    await render(
      <template>
        <Select @defaultValue="banana" as |s|>
          <s.Trigger aria-label="Fruit"><s.Value @placeholder="Select a fruit" /></s.Trigger>
          <s.Content>
            <s.Viewport>
              {{#each fruits as |fruit|}}
                <s.Item @value={{fruit.value}} as |item|>
                  <item.ItemText>{{fruit.label}}</item.ItemText>
                  <item.ItemIndicator>✓</item.ItemIndicator>
                </s.Item>
              {{/each}}
            </s.Viewport>
          </s.Content>
        </Select>
      </template>,
    )
    const select = new SelectHarness()
    assert.strictEqual(select.valueText, 'Banana', 'the chosen option’s text, while closed')
    assert.false(select.isPlaceholder)

    await select.open()
    assert.true(select.isOpen)
    assert.true(select.isShown, 'in the top layer')
    assert.dom(select.trigger).hasAttribute('aria-controls', select.content!.id)
    assert.dom(select.content).hasAttribute('role', 'listbox').hasAttribute('data-state', 'open')
    assert.strictEqual(select.contentLabel, 'Fruit', 'named by its trigger')
    assert.deepEqual(select.options, ['apple', 'banana', 'blueberry', 'grapes', 'pineapple'])
    assert.true(select.isOptionSelected('banana'))
    assert.dom(select.option('banana')).isFocused('focus goes to the chosen option')
    assert.strictEqual(select.highlighted, 'banana')
    assert.dom(select.option('banana')).hasAttribute('aria-selected', 'true')
    assert.dom('[data-test-jn-part="option-indicator"]', select.option('banana')).hasText('✓')
    assert.dom('[data-test-jn-part="option-indicator"]', select.option('apple')).doesNotExist()
    assert
      .dom(select.option('apple'))
      .hasAttribute('aria-labelledby', select.option('apple').querySelector('span')!.id)
    await a11yAudit()

    await select.pressOption('grapes')
    assert.false(select.isOpen)
    assert.strictEqual(select.value, 'grapes')
    assert.strictEqual(select.valueText, 'Grapes')
    assert.true(select.isFocused, 'focus is back on the trigger')
    await a11yAudit()
  })

  test('controlled: @value and @onValueChange, @open and @onOpenChange', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Select
          @value={{state.value}}
          @onValueChange={{state.setValue}}
          @open={{state.open}}
          @onOpenChange={{state.setOpen}}
          as |s|
        >
          <s.Trigger aria-label="Fruit"><s.Value /></s.Trigger>
          <s.Content>
            <s.Viewport>
              {{#each fruits as |fruit|}}
                <s.Item @value={{fruit.value}} as |item|>
                  <item.ItemText>{{fruit.label}}</item.ItemText>
                </s.Item>
              {{/each}}
            </s.Viewport>
          </s.Content>
        </Select>
      </template>,
    )
    const select = new SelectHarness()
    assert.strictEqual(select.valueText, 'Banana')
    await select.open()
    assert.deepEqual(state.opens, [true])
    assert.true(select.isOpen)
    await select.pressOption('apple')
    assert.deepEqual(state.values, ['apple'])
    assert.deepEqual(state.opens, [true, false])
    assert.strictEqual(select.valueText, 'Apple')

    state.value = 'pineapple'
    await settled()
    assert.strictEqual(select.valueText, 'Pineapple', 'it shows the value it is given')
    state.open = true
    await settled()
    assert.true(select.isOpen, 'and opens when told')
    assert.dom(select.option('pineapple')).isFocused()
    await a11yAudit()
    state.open = false
    await settled()
  })

  test('keyboard: Enter, Space and the arrows open it; arrows, Home and End move; Enter chooses; Escape closes', async function (assert) {
    await render(
      <template>
        <Select as |s|>
          <s.Trigger aria-label="Fruit"><s.Value @placeholder="Pick" /></s.Trigger>
          <s.Content>
            <s.Viewport>
              {{#each fruits as |fruit|}}
                <s.Item @value={{fruit.value}} @disabled={{isGrapes fruit.value}} as |item|>
                  <item.ItemText>{{fruit.label}}</item.ItemText>
                </s.Item>
              {{/each}}
            </s.Viewport>
          </s.Content>
        </Select>
      </template>,
    )
    const select = new SelectHarness()
    for (const key of ['Enter', ' ', 'ArrowDown', 'ArrowUp'] as const) {
      await select.openWithKeyboard(key)
      assert.true(select.isOpen, `${key === ' ' ? 'Space' : key} opens it`)
      assert.dom(select.option('apple')).isFocused('with nothing chosen, the first option')
      await select.pressEscape()
      assert.false(select.isOpen)
      assert.true(select.isFocused, 'Escape returns focus to the trigger')
    }

    await select.openWithKeyboard()
    await pressKey('ArrowDown')
    assert.dom(select.option('banana')).isFocused()
    await pressKey('ArrowDown')
    await pressKey('ArrowDown')
    assert.dom(select.option('pineapple')).isFocused('skipping the disabled option')
    assert.true(select.isOptionDisabled('grapes'))
    assert.dom(select.option('grapes')).hasAttribute('data-disabled', '')
    await pressKey('ArrowDown')
    assert.dom(select.option('pineapple')).isFocused('no wrapping')
    await pressKey('Home')
    assert.dom(select.option('apple')).isFocused()
    await pressKey('End')
    assert.dom(select.option('pineapple')).isFocused()
    await pressKey('ArrowUp')
    assert.dom(select.option('blueberry')).isFocused()
    assert.true(await pressKey('Tab'), 'Tab does nothing inside it')
    assert.true(select.isOpen)
    await pressKey('Enter')
    assert.false(select.isOpen)
    assert.strictEqual(select.value, 'blueberry')
    assert.true(select.isFocused)

    await pressKey(' ')
    assert.dom(select.option('blueberry')).isFocused('it opens on the chosen option')
    await pressKey(' ')
    assert.strictEqual(select.value, 'blueberry', 'Space chooses too')
    assert.false(select.isOpen)
    await a11yAudit()
  })

  test('typeahead: on the closed trigger it chooses, in the open list it moves focus', async function (assert) {
    await render(
      <template>
        <Select as |s|>
          <s.Trigger aria-label="Fruit"><s.Value @placeholder="Pick" /></s.Trigger>
          <s.Content>
            <s.Viewport>
              {{#each fruits as |fruit|}}
                <s.Item @value={{fruit.value}} as |item|>
                  <item.ItemText>{{fruit.label}}</item.ItemText>
                </s.Item>
              {{/each}}
            </s.Viewport>
          </s.Content>
        </Select>
      </template>,
    )
    const select = new SelectHarness()
    await select.focus()
    await select.typeahead('b')
    assert.false(select.isOpen, 'it stays closed')
    assert.strictEqual(select.value, 'banana', '"b" chooses Banana')
    await select.typeahead('b')
    assert.strictEqual(select.value, 'blueberry', '"b" again moves on')
    await new Promise(resolve => setTimeout(resolve, 1050))

    await select.openWithKeyboard()
    assert.dom(select.option('blueberry')).isFocused()
    await select.typeahead('pi')
    assert.dom(select.option('pineapple')).isFocused()
    assert.true(select.isOpen)
    await select.typeahead(' ')
    assert.true(select.isOpen, 'Space while typing is part of the search')
    await a11yAudit()
  })

  test('a disabled select doesn’t open, and a disabled option can’t be chosen', async function (assert) {
    await render(
      <template>
        <Select @disabled={{true}} @name="off" as |s|>
          <s.Trigger aria-label="Fruit"><s.Value @placeholder="Pick" /></s.Trigger>
          <s.Content><s.Viewport>
              <s.Item @value="apple" as |item|><item.ItemText>Apple</item.ItemText></s.Item>
            </s.Viewport></s.Content>
        </Select>
        <Select @name="on" as |s|>
          <s.Trigger aria-label="Fruit"><s.Value @placeholder="Pick" /></s.Trigger>
          <s.Content><s.Viewport>
              <s.Item @value="apple" @disabled={{true}} as |item|>
                <item.ItemText>Apple</item.ItemText>
              </s.Item>
              <s.Item @value="banana" as |item|><item.ItemText>Banana</item.ItemText></s.Item>
            </s.Viewport></s.Content>
        </Select>
      </template>,
    )
    const off = new SelectHarness('off')
    assert.true(off.isDisabled)
    assert.dom(off.trigger).isDisabled()
    assert.false(off.isOpen)

    const on = new SelectHarness('on')
    await on.open()
    assert.dom(on.option('banana')).isFocused('the first option that isn’t disabled')
    await on.pressOption('apple')
    assert.true(on.isOpen, 'a press on a disabled option does nothing')
    assert.strictEqual(on.value, '')
    await a11yAudit()
    await on.close()
  })

  test('groups are named by their labels, and separators are hidden from assistive technology', async function (assert) {
    await render(
      <template>
        <Select as |s|>
          <s.Trigger aria-label="Food"><s.Value @placeholder="Pick" /></s.Trigger>
          <s.Content>
            <s.Viewport>
              <s.Group>
                <s.Label>Fruits</s.Label>
                <s.Item @value="apple" as |item|><item.ItemText>Apple</item.ItemText></s.Item>
              </s.Group>
              <s.Separator />
              <s.Group>
                <s.Label>Vegetables</s.Label>
                <s.Item @value="carrot" as |item|><item.ItemText>Carrot</item.ItemText></s.Item>
                <s.Item @value="leek" as |item|><item.ItemText>Leek</item.ItemText></s.Item>
              </s.Group>
            </s.Viewport>
          </s.Content>
        </Select>
      </template>,
    )
    const select = new SelectHarness()
    await select.open()
    assert.deepEqual(select.groups, ['Fruits', 'Vegetables'])
    assert.deepEqual(select.optionsIn('Vegetables'), ['carrot', 'leek'])
    assert.dom('[data-test-jn-part="group"]').hasAttribute('role', 'group')
    assert.dom('[data-test-jn-part="separator"]').hasAttribute('aria-hidden', 'true')
    await a11yAudit()
  })

  test('item-aligned: the chosen option’s text sits over the value, and the content is as wide as the trigger', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="sel-stage">
          <Select @defaultValue="blueberry" as |s|>
            <s.Trigger class="sel-trigger" aria-label="Fruit">
              <s.Value @placeholder="Pick" />
            </s.Trigger>
            <s.Content class="sel-content">
              <s.Viewport class="sel-viewport">
                {{#each fruits as |fruit|}}
                  <s.Item class="sel-item" @value={{fruit.value}} as |item|>
                    <item.ItemText>{{fruit.label}}</item.ItemText>
                  </s.Item>
                {{/each}}
              </s.Viewport>
            </s.Content>
          </Select>
        </div>
      </template>,
    )
    const select = new SelectHarness()
    await select.open()
    assert.strictEqual(select.position, 'item-aligned')
    const value = rect(select.queryPart('value')!)
    const text = rect(select.option('blueberry').querySelector('span')!)
    near(assert, text.left, value.left, 'the option’s text starts where the value does')
    near(
      assert,
      text.top + text.height / 2,
      value.top + value.height / 2,
      'and sits on the same line',
    )
    assert.true(
      rect(select.content!).width >= rect(select.trigger).width - 1,
      'at least as wide as the trigger',
    )
    await a11yAudit()
  })

  test('item-aligned, right to left: the text lines up at the right', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="sel-stage">
          <DirectionProvider @dir="rtl">
            <Select @defaultValue="banana" as |s|>
              <s.Trigger class="sel-trigger" aria-label="فاكهة"><s.Value /></s.Trigger>
              <s.Content class="sel-content">
                <s.Viewport>
                  <s.Item class="sel-item" @value="apple" as |item|>
                    <item.ItemText>تفاح</item.ItemText>
                  </s.Item>
                  <s.Item class="sel-item" @value="banana" as |item|>
                    <item.ItemText>موز</item.ItemText>
                  </s.Item>
                </s.Viewport>
              </s.Content>
            </Select>
          </DirectionProvider>
        </div>
      </template>,
    )
    const select = new SelectHarness()
    await select.open()
    const value = rect(select.queryPart('value')!)
    const text = rect(select.option('banana').querySelector('span')!)
    near(assert, text.right, value.right, 'the option’s text ends where the value does')
    await pressKey('ArrowUp')
    assert.dom(select.option('apple')).isFocused('the arrows stay vertical')
    await a11yAudit()
  })

  test('scroll buttons show while the options can scroll, and a pointer over one scrolls', async function (assert) {
    await render(
      <template>
        <Styles />
        <div style="position: fixed; top: 20px; left: 20px">
          <Select as |s|>
            <s.Trigger class="sel-trigger" aria-label="Number"><s.Value
                @placeholder="Pick"
              /></s.Trigger>
            <s.Content class="sel-content" @position="popper" style="max-height: 120px">
              <s.ScrollUpButton>▲</s.ScrollUpButton>
              <s.Viewport>
                {{#each fruits as |fruit|}}
                  <s.Item class="sel-item" @value={{fruit.value}} as |item|>
                    <item.ItemText>{{fruit.label}}</item.ItemText>
                  </s.Item>
                {{/each}}
              </s.Viewport>
              <s.ScrollDownButton>▼</s.ScrollDownButton>
            </s.Content>
          </Select>
        </div>
      </template>,
    )
    const select = new SelectHarness()
    await select.open()
    assert.false(select.canScrollUp, 'at the top, nothing above')
    assert.true(select.canScrollDown, 'more below')
    const down = select.part('scroll-down-button')
    assert.dom(down).hasAttribute('aria-hidden', 'true').hasText('▼')
    const viewport = select.part('viewport')
    await triggerEvent(down, 'pointermove', { pointerType: 'mouse' })
    await waitUntil(() => viewport.scrollTop > 0, { timeout: 2000 })
    await triggerEvent(down, 'pointerleave', { pointerType: 'mouse' })
    assert.true(viewport.scrollTop > 0, `it scrolled (${viewport.scrollTop})`)
    // The viewport's scroll event comes a frame later, which `settled()` doesn't wait for: the
    // buttons follow a scroll the select makes itself as it makes it.
    assert.true(select.canScrollUp, 'and now there is something above')
    await pressKey('End')
    assert.dom(select.option('pineapple')).isFocused()
    assert.false(select.canScrollDown, 'at the bottom, nothing below')
    await pressKey('Home')
    assert.dom(select.option('apple')).isFocused()
    assert.false(select.canScrollUp, 'back at the top, nothing above')
    assert.true(select.canScrollDown, 'and more below again')
    await a11yAudit()
  })

  test('a press outside closes it; window blur closes it', async function (assert) {
    await render(
      <template>
        <Select as |s|>
          <s.Trigger aria-label="Fruit"><s.Value @placeholder="Pick" /></s.Trigger>
          <s.Content><s.Viewport>
              <s.Item @value="apple" as |item|><item.ItemText>Apple</item.ItemText></s.Item>
            </s.Viewport></s.Content>
        </Select>
      </template>,
    )
    const select = new SelectHarness()
    await select.open()
    assert.dom(select.trigger).hasAttribute('inert', '', 'the rest of the page is inert')
    await select.pressOutside()
    assert.false(select.isOpen)
    assert.dom(select.trigger).doesNotHaveAttribute('inert')
    await select.open()
    window.dispatchEvent(new Event('blur'))
    await settled()
    assert.false(select.isOpen)
    await a11yAudit()
  })

  test('in a form, a hidden native select carries the value under @formName and tells the form', async function (assert) {
    const changes: string[] = []
    const onChange = (event: Event) => changes.push((event.target as HTMLSelectElement).value)
    await render(
      <template>
        {{! Named form element, not form: a local named form would turn <form> into a call to it. }}
        <form id="order" {{on "change" onChange}}>
          <Select @formName="fruit" @required={{true}} @defaultValue="apple" as |s|>
            <s.Trigger aria-label="Fruit"><s.Value /></s.Trigger>
            <s.Content><s.Viewport>
                {{#each fruits as |fruit|}}
                  <s.Item @value={{fruit.value}} as |item|>
                    <item.ItemText>{{fruit.label}}</item.ItemText>
                  </s.Item>
                {{/each}}
              </s.Viewport></s.Content>
          </Select>
        </form>
      </template>,
    )
    const select = new SelectHarness()
    await rerender()
    const native = select.nativeSelect!
    assert.dom(native).hasAttribute('name', 'fruit').hasAttribute('aria-hidden', 'true')
    assert.dom(native).hasAttribute('tabindex', '-1').isRequired()
    assert.strictEqual(native.value, 'apple')
    assert.true(select.isRequired, 'aria-required on the trigger')
    assert.deepEqual(
      [...native.options].map(option => option.value),
      fruits.map(fruit => fruit.value),
    )
    assert.strictEqual(
      new FormData(find('#order') as HTMLFormElement).get('fruit'),
      'apple',
      'the form data has it',
    )
    await select.select('pineapple')
    await settled()
    assert.strictEqual(native.value, 'pineapple')
    assert.deepEqual(changes, ['pineapple'], 'a change event bubbled to the form')
    await a11yAudit()
  })

  test('Tab leaves the closed select, and the open one keeps focus inside', async function (assert) {
    await render(
      <template>
        <button type="button" id="before">Before</button>
        <Select as |s|>
          <s.Trigger aria-label="Fruit"><s.Value @placeholder="Pick" /></s.Trigger>
          <s.Content><s.Viewport>
              <s.Item @value="apple" as |item|><item.ItemText>Apple</item.ItemText></s.Item>
            </s.Viewport></s.Content>
        </Select>
        <button type="button" id="after">After</button>
      </template>,
    )
    const select = new SelectHarness()
    await focus('#before')
    await tab()
    assert.true(select.isFocused, 'the trigger is in the tab order')
    await tab()
    assert.dom('#after').isFocused()
    await a11yAudit()
  })
})

module('Integration | primitives | select (Floating UI)', function (hooks) {
  setupRenderingTest(hooks)
  setupAnchorFallback(hooks)

  test('popper: below the trigger, at its start, with Radix’s custom properties', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="sel-stage">
          <Select as |s|>
            <s.Trigger class="sel-trigger" aria-label="Fruit"><s.Value
                @placeholder="Pick"
              /></s.Trigger>
            <s.Content class="sel-content" @position="popper" @sideOffset={{4}}>
              <s.Viewport>
                <s.Item class="sel-item" @value="apple" as |item|>
                  <item.ItemText>Apple</item.ItemText>
                </s.Item>
              </s.Viewport>
            </s.Content>
          </Select>
        </div>
      </template>,
    )
    const select = new SelectHarness()
    await select.open()
    assert.strictEqual(select.position, 'popper')
    const t = rect(select.trigger)
    const c = rect(select.content!)
    near(assert, c.top, t.bottom + 4, 'below, 4px off')
    near(assert, c.left, t.left, 'at the start')
    assert.strictEqual(select.side, 'bottom')
    assert.strictEqual(
      select.content!.style.getPropertyValue('--radix-select-trigger-width'),
      'var(--jn-anchor-width)',
    )
    assert.strictEqual(
      getComputedStyle(select.content!).getPropertyValue('--jn-anchor-width'),
      `${t.width}px`,
      'as wide as the trigger',
    )
    await a11yAudit()
  })
})
