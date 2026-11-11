import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { focus, render, settled, triggerEvent } from '@ember/test-helpers'
import { array, get } from '@ember/helper'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Combobox } from '@ember-joinery/primitives/combobox'
import { ComboboxHarness, hover, pressKey } from '@ember-joinery/test-support'

const frameworks = ['Next.js', 'SvelteKit', 'Nuxt.js', 'Remix', 'Astro']

const timezones = [
  { value: 'Americas', items: ['(GMT-5) New York', '(GMT-8) Los Angeles'] },
  { value: 'Europe', items: ['(GMT+0) London', '(GMT+1) Paris'] },
]

const isFirst = (index: number) => index === 0

class State {
  @tracked value: unknown = null
  @tracked inputValue = ''
  values: unknown[] = []
  inputs: string[] = []
  setValue = (value: unknown) => {
    this.values.push(value)
    this.value = value
  }
  setInputValue = (value: string) => {
    this.inputs.push(value)
    this.inputValue = value
  }
}

module('Integration | primitives | combobox', function (hooks) {
  setupRenderingTest(hooks)

  test('the input is a combobox for a listbox, and the list renders only while open', async function (assert) {
    await render(
      <template>
        <Combobox @name="framework" @items={{frameworks}} as |c|>
          <c.Input placeholder="Select a framework" />
          <c.Content>
            <c.Empty>No items found.</c.Empty>
            <c.List as |item|><c.Item @value={{item}}>{{item}}</c.Item></c.List>
          </c.Content>
        </Combobox>
      </template>,
    )
    const combobox = new ComboboxHarness('framework')
    assert
      .dom(combobox.input)
      .hasAttribute('role', 'combobox')
      .hasAttribute('aria-expanded', 'false')
      .hasAttribute('aria-haspopup', 'listbox')
      .hasAttribute('aria-autocomplete', 'list')
      .hasAttribute('autocomplete', 'off')
      .doesNotHaveAttribute('aria-controls')
    assert.strictEqual(combobox.label, 'Select a framework', 'named by its placeholder')
    assert.strictEqual(combobox.content, null)

    await combobox.open()
    assert.true(combobox.isOpen)
    assert.true(combobox.isShown, 'in the top layer')
    assert.dom(combobox.input).hasAttribute('aria-controls', combobox.list!.id)
    assert.dom(combobox.list).hasAttribute('role', 'listbox')
    assert.dom(combobox.content).hasAttribute('data-open', '').hasAttribute('role', 'presentation')
    assert.deepEqual(combobox.items, frameworks)
    assert.strictEqual(combobox.highlighted, null, 'a press opens it with nothing highlighted')
    assert.dom(combobox.input).isFocused('focus stays in the input')
    assert.strictEqual(combobox.emptyText, '', 'Empty says nothing while there are items')
    await a11yAudit()
  })

  test('typing filters the items, ignoring case and accents, and Empty speaks when nothing matches', async function (assert) {
    await render(
      <template>
        <Combobox @items={{frameworks}} as |c|>
          <c.Input placeholder="Select a framework" />
          <c.Content>
            <c.Empty>No items found.</c.Empty>
            <c.List as |item|><c.Item @value={{item}}>{{item}}</c.Item></c.List>
          </c.Content>
        </Combobox>
      </template>,
    )
    const combobox = new ComboboxHarness()
    await combobox.type('nu')
    assert.true(combobox.isOpen, 'typing opens it')
    assert.deepEqual(combobox.items, ['Nuxt.js'])
    await combobox.deleteBackward(2)
    assert.deepEqual(combobox.items, frameworks, 'an empty query shows everything')
    await combobox.type('ÁSTRO')
    assert.deepEqual(combobox.items, ['Astro'], 'case and accents are ignored')
    await combobox.type('x')
    assert.deepEqual(combobox.items, [])
    assert.true(combobox.isEmpty)
    assert.dom(combobox.content).hasAttribute('data-empty', '')
    assert.strictEqual(combobox.emptyText, 'No items found.')
    assert.dom(combobox.queryPart('empty')).hasAttribute('role', 'status')
    await a11yAudit()
  })

  test('keyboard: the arrows open and move the highlight round, Enter chooses, Escape closes and then clears', async function (assert) {
    await render(
      <template>
        <Combobox @items={{frameworks}} as |c|>
          <c.Input placeholder="Select a framework" />
          <c.Content>
            <c.List as |item|><c.Item @value={{item}}>{{item}}</c.Item></c.List>
          </c.Content>
        </Combobox>
      </template>,
    )
    const combobox = new ComboboxHarness()
    await combobox.focus()
    await pressKey('ArrowDown')
    assert.true(combobox.isOpen, 'ArrowDown opens it')
    assert.strictEqual(combobox.highlighted, 'Next.js', 'on the first item')
    assert.dom(combobox.item('Next.js')).hasAttribute('data-highlighted', '')
    await pressKey('ArrowDown')
    assert.strictEqual(combobox.highlighted, 'SvelteKit')
    await pressKey('ArrowUp')
    await pressKey('ArrowUp')
    assert.strictEqual(combobox.highlighted, null, 'up from the first: back to the input')
    await pressKey('ArrowUp')
    assert.strictEqual(combobox.highlighted, 'Astro', 'and round to the last')
    await pressKey('ArrowDown')
    assert.strictEqual(combobox.highlighted, null, 'down from the last: back to the input')
    await pressKey('ArrowDown')
    assert.strictEqual(combobox.highlighted, 'Next.js')
    await pressKey('ArrowDown')
    await pressKey('Enter')
    assert.false(combobox.isOpen)
    assert.strictEqual(combobox.inputValue, 'SvelteKit', 'the input shows the chosen label')
    assert.dom(combobox.input).isFocused()

    await pressKey('ArrowDown')
    assert.strictEqual(combobox.highlighted, 'SvelteKit', 'reopened on the chosen item')
    assert.deepEqual(combobox.items, frameworks, 'its label doesn’t filter the list')
    assert.true(combobox.isItemSelected('SvelteKit'))
    await combobox.pressEscape()
    assert.false(combobox.isOpen, 'Escape closes it')
    assert.strictEqual(combobox.inputValue, 'SvelteKit')
    await combobox.pressEscape()
    assert.strictEqual(combobox.inputValue, '', 'Escape on the closed list clears it')
    await combobox.open()
    assert.false(combobox.isItemSelected('SvelteKit'), 'and the value')
    await a11yAudit()
  })

  test('the pointer: hovering highlights, a press chooses, a press outside closes and puts the label back', async function (assert) {
    await render(
      <template>
        <Combobox @items={{frameworks}} @defaultValue="Remix" as |c|>
          <c.Input placeholder="Select a framework" />
          <c.Content>
            <c.List as |item|>
              <c.Item @value={{item}} as |i|>{{item}}<i.ItemIndicator>✓</i.ItemIndicator></c.Item>
            </c.List>
          </c.Content>
        </Combobox>
      </template>,
    )
    const combobox = new ComboboxHarness()
    assert.strictEqual(combobox.inputValue, 'Remix', 'the input starts with the value’s label')
    await combobox.open()
    assert.strictEqual(combobox.highlighted, 'Remix', 'opened on the chosen item')
    assert.dom('[data-test-jn-part="item-indicator"]', combobox.item('Remix')).hasText('✓')
    assert.dom('[data-test-jn-part="item-indicator"]', combobox.item('Astro')).doesNotExist()
    await hover(combobox.item('Astro'))
    assert.strictEqual(combobox.highlighted, 'Astro')
    await combobox.pressItem('Astro')
    assert.false(combobox.isOpen)
    assert.strictEqual(combobox.inputValue, 'Astro')

    await combobox.type('x')
    assert.strictEqual(combobox.inputValue, 'Astrox')
    await combobox.pressOutside()
    assert.false(combobox.isOpen)
    assert.strictEqual(combobox.inputValue, 'Astro', 'what was typed gives way to the value')
    await a11yAudit()
  })

  test('controlled: @value with @onValueChange, @inputValue with @onInputValueChange', async function (assert) {
    const state = new State()
    state.value = 'Nuxt.js'
    state.inputValue = 'Nuxt.js'
    await render(
      <template>
        <Combobox
          @items={{frameworks}}
          @value={{state.value}}
          @onValueChange={{state.setValue}}
          @inputValue={{state.inputValue}}
          @onInputValueChange={{state.setInputValue}}
          as |c|
        >
          <c.Input placeholder="Select a framework" />
          <c.Content>
            <c.List as |item|><c.Item @value={{item}}>{{item}}</c.Item></c.List>
          </c.Content>
        </Combobox>
      </template>,
    )
    const combobox = new ComboboxHarness()
    await combobox.type('?')
    assert.deepEqual(state.inputs, ['Nuxt.js?'])
    await combobox.deleteBackward()
    await combobox.deleteBackward(7)
    assert.deepEqual(state.values, [null], 'emptying the input clears the value')
    await combobox.type('re')
    await combobox.pressItem('Remix')
    assert.deepEqual(state.values, [null, 'Remix'])
    assert.strictEqual(state.inputValue, 'Remix')
    state.value = 'Astro'
    state.inputValue = 'Astro'
    await settled()
    assert.strictEqual(combobox.inputValue, 'Astro', 'it shows what it is given')
    await a11yAudit()
  })

  test('autoHighlight highlights the first match as you type', async function (assert) {
    await render(
      <template>
        <Combobox @items={{frameworks}} @autoHighlight={{true}} as |c|>
          <c.Input placeholder="Select a framework" />
          <c.Content>
            <c.List as |item|><c.Item @value={{item}}>{{item}}</c.Item></c.List>
          </c.Content>
        </Combobox>
      </template>,
    )
    const combobox = new ComboboxHarness()
    await combobox.type('s')
    assert.deepEqual(combobox.items, ['Next.js', 'SvelteKit', 'Nuxt.js', 'Astro'])
    assert.strictEqual(combobox.highlighted, 'Next.js')
    await combobox.type('v')
    assert.strictEqual(combobox.highlighted, 'SvelteKit')
    await pressKey('Enter')
    assert.strictEqual(combobox.inputValue, 'SvelteKit')
    await a11yAudit()
  })

  test('multiple: chips for the chosen items, Backspace and the remove buttons take them off', async function (assert) {
    await render(
      <template>
        <Combobox @items={{frameworks}} @multiple={{true}} @defaultValue={{array "Next.js"}} as |c|>
          <div {{c.chips}}>
            <c.Value as |values|>
              {{#each values as |value|}}
                <c.Chip @value={{value}} as |chip|>
                  {{value}}
                  <chip.Remove aria-label="Remove {{value}}">×</chip.Remove>
                </c.Chip>
              {{/each}}
              <c.Input aria-label="Frameworks" />
            </c.Value>
          </div>
          <c.Content @anchor={{c.chipsElement}}>
            <c.List as |item|><c.Item @value={{item}}>{{item}}</c.Item></c.List>
          </c.Content>
        </Combobox>
      </template>,
    )
    const combobox = new ComboboxHarness()
    assert.deepEqual(combobox.chips, ['Next.js'])
    assert.dom('[data-test-jn-part="chips"]').hasAttribute('role', 'toolbar')
    await combobox.open()
    assert.dom(combobox.list).hasAttribute('aria-multiselectable', 'true')
    await combobox.pressItem('Remix')
    assert.true(combobox.isOpen, 'it stays open to choose more')
    assert.deepEqual(combobox.chips, ['Next.js', 'Remix'])
    assert.true(combobox.isItemSelected('Remix'))
    await combobox.pressItem('Next.js')
    assert.deepEqual(combobox.chips, ['Remix'], 'choosing a chosen item takes it off')

    await combobox.type('as')
    await combobox.pressItem('Astro')
    assert.false(combobox.isOpen, 'choosing while filtering closes it')
    assert.strictEqual(combobox.inputValue, '', 'and empties the input')
    assert.deepEqual(combobox.chips, ['Remix', 'Astro'])

    await combobox.focus()
    await pressKey('Backspace')
    assert.deepEqual(combobox.chips, ['Remix'], 'Backspace in the empty input takes the last off')
    await combobox.removeChip('Remix')
    assert.deepEqual(combobox.chips, [])
    assert.dom(combobox.input).isFocused('focus goes back to the input')
    await a11yAudit()
  })

  test('chips: the start arrow moves into them, and Backspace on one removes it', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Combobox
            @items={{frameworks}}
            @multiple={{true}}
            @defaultValue={{array "Next.js" "Remix"}}
            as |c|
          >
            <div {{c.chips}}>
              <c.Value as |values|>
                {{#each values as |value|}}<c.Chip @value={{value}}>{{value}}</c.Chip>{{/each}}
              </c.Value>
              <c.Input aria-label="أطر العمل" />
            </div>
            <c.Content><c.List as |item|><c.Item
                  @value={{item}}
                >{{item}}</c.Item></c.List></c.Content>
          </Combobox>
        </DirectionProvider>
      </template>,
    )
    const combobox = new ComboboxHarness()
    await combobox.focus()
    await pressKey('ArrowRight')
    assert
      .dom(combobox.chip('Remix'))
      .isFocused('right to left, ArrowRight goes back to the last chip')
    await pressKey('ArrowRight')
    await settled()
    assert.dom(combobox.chip('Next.js')).isFocused()
    await pressKey('ArrowLeft')
    await settled()
    assert.dom(combobox.chip('Remix')).isFocused()
    await pressKey('Backspace')
    assert.deepEqual(combobox.chips, ['Next.js'])
    await settled()
    assert.dom(combobox.chip('Next.js')).isFocused('focus moves to the chip before')
    await pressKey('a')
    assert.dom(combobox.input).isFocused('typing goes back to the input')
    await a11yAudit()
  })

  test('groups: the filter keeps the groups that match, each named by its label', async function (assert) {
    await render(
      <template>
        <Combobox @items={{timezones}} as |c|>
          <c.Input placeholder="Select a timezone" />
          <c.Content>
            <c.Empty>No timezones found.</c.Empty>
            <c.List as |group index|>
              <c.Group @items={{group.items}} as |g|>
                <c.GroupLabel>{{group.value}}</c.GroupLabel>
                <g.Collection as |item|><c.Item @value={{item}}>{{item}}</c.Item></g.Collection>
                {{! Inside the group, between groups, as upstream's example puts it. }}
                {{#if (isFirst index)}}<c.Separator />{{/if}}
              </c.Group>
            </c.List>
          </c.Content>
        </Combobox>
      </template>,
    )
    const combobox = new ComboboxHarness()
    await combobox.open()
    assert.deepEqual(combobox.groups, ['Americas', 'Europe'])
    assert.strictEqual(combobox.items.length, 4)
    await combobox.type('par')
    assert.deepEqual(combobox.groups, ['Europe'], 'a group with no match goes')
    assert.deepEqual(combobox.items, ['(GMT+1) Paris'])
    assert.dom('[data-test-jn-part="separator"]').hasAttribute('aria-hidden', 'true')
    await a11yAudit()
  })

  test('the trigger and the clear button', async function (assert) {
    await render(
      <template>
        <Combobox @items={{frameworks}} @defaultValue="Astro" as |c|>
          <c.Input placeholder="Select a framework" />
          <c.Trigger aria-label="Show frameworks">▼</c.Trigger>
          <c.Clear aria-label="Clear" />
          <c.Content><c.List as |item|><c.Item
                @value={{item}}
              >{{item}}</c.Item></c.List></c.Content>
        </Combobox>
      </template>,
    )
    const combobox = new ComboboxHarness()
    assert
      .dom(combobox.trigger)
      .hasAttribute('tabindex', '-1')
      .hasAttribute('aria-haspopup', 'listbox')
    await combobox.pressTrigger()
    assert.true(combobox.isOpen)
    assert
      .dom(combobox.trigger)
      .hasAttribute('data-popup-open', '')
      .hasAttribute('aria-expanded', 'true')
    assert.dom(combobox.input).isFocused('focus goes to the input')
    await combobox.pressTrigger()
    assert.false(combobox.isOpen, 'a second press closes it')

    assert.dom(combobox.clearButton).hasText('x').hasAttribute('tabindex', '-1')
    await combobox.clear()
    assert.strictEqual(combobox.inputValue, '')
    assert.strictEqual(combobox.clearButton, null, 'nothing left to clear')
    assert.dom(combobox.input).isFocused()
    await a11yAudit()
  })

  test('disabled: the input and its buttons don’t open it', async function (assert) {
    await render(
      <template>
        <Combobox @items={{frameworks}} @disabled={{true}} as |c|>
          <c.Input placeholder="Select a framework" />
          <c.Trigger aria-label="Show frameworks">▼</c.Trigger>
          <c.Content><c.List as |item|><c.Item
                @value={{item}}
              >{{item}}</c.Item></c.List></c.Content>
        </Combobox>
      </template>,
    )
    const combobox = new ComboboxHarness()
    assert.true(combobox.isDisabled)
    assert.dom(combobox.input).isDisabled()
    assert.dom(combobox.trigger).isDisabled()
    await a11yAudit()
  })

  test('the input inside the popup: the trigger is the combobox, and focus goes in and back', async function (assert) {
    const countries = [
      { value: '', label: 'Select country' },
      { value: 'ar', label: 'Argentina' },
      { value: 'au', label: 'Australia' },
      { value: 'br', label: 'Brazil' },
    ]
    await render(
      <template>
        <Combobox @items={{countries}} @defaultValue={{get countries 0}} as |c|>
          <button type="button" aria-label="Country" {{c.trigger}}><c.Value /></button>
          <c.Content>
            <c.Input placeholder="Search" />
            <c.List as |item|><c.Item @value={{item}}>{{get item "label"}}</c.Item></c.List>
          </c.Content>
        </Combobox>
      </template>,
    )
    const combobox = new ComboboxHarness()
    const trigger = combobox.trigger!
    assert
      .dom(trigger)
      .hasText('Select country', 'the Value shows the chosen item’s label')
      .hasAttribute('role', 'combobox')
      .hasAttribute('aria-haspopup', 'dialog')
      .hasAttribute('tabindex', '0')
    assert.strictEqual(combobox.input, null)
    await combobox.pressTrigger()
    assert.true(combobox.isOpen)
    assert.dom(combobox.content).hasAttribute('role', 'dialog')
    assert.dom(combobox.input).isFocused('focus goes to the input in the popup')
    assert.strictEqual(combobox.inputValue, '', 'which starts empty, for a search')
    await combobox.type('bra')
    assert.deepEqual(combobox.items, ['Brazil'])
    await pressKey('ArrowDown')
    assert.strictEqual(combobox.highlighted, 'Brazil')
    await pressKey('Enter')
    assert.false(combobox.isOpen)
    assert.dom(trigger).hasText('Brazil').isFocused('focus goes back to the trigger')
    await combobox.pressTrigger()
    assert.strictEqual(combobox.inputValue, '', 'the search starts empty again')
    await combobox.pressEscape()
    await a11yAudit()
  })

  test('filtering elsewhere: @filter={{null}} shows @items as given, for results from a server', async function (assert) {
    class Search {
      @tracked items: string[] = []
      queries: string[] = []
      search = (query: string) => {
        this.queries.push(query)
        // A server's answer, after a delay.
        void Promise.resolve().then(() => {
          this.items = frameworks.filter(name => name.toLowerCase().startsWith(query.toLowerCase()))
        })
      }
    }
    const search = new Search()
    await render(
      <template>
        <Combobox
          @items={{search.items}}
          @filter={{null}}
          @onInputValueChange={{search.search}}
          as |c|
        >
          <c.Input placeholder="Search frameworks" />
          <c.Content>
            <c.Empty>No results.</c.Empty>
            <c.List as |item|><c.Item @value={{item}}>{{item}}</c.Item></c.List>
          </c.Content>
        </Combobox>
      </template>,
    )
    const combobox = new ComboboxHarness()
    await combobox.type('n')
    await settled()
    assert.deepEqual(search.queries, ['n'])
    assert.deepEqual(combobox.items, ['Next.js', 'Nuxt.js'], 'the server’s items, unfiltered')
    await combobox.type('e')
    await settled()
    assert.deepEqual(combobox.items, ['Next.js'])
    await combobox.pressItem('Next.js')
    assert.strictEqual(combobox.inputValue, 'Next.js')
    await a11yAudit()
  })

  test('in a form, hidden inputs carry each value under @formName', async function (assert) {
    await render(
      <template>
        <form id="stack">
          <Combobox
            @items={{frameworks}}
            @multiple={{true}}
            @formName="frameworks"
            @defaultValue={{array "Remix" "Astro"}}
            as |c|
          >
            <c.Input aria-label="Frameworks" />
            <c.Content><c.List as |item|><c.Item
                  @value={{item}}
                >{{item}}</c.Item></c.List></c.Content>
          </Combobox>
        </form>
      </template>,
    )
    const combobox = new ComboboxHarness()
    assert.deepEqual(combobox.formValues, ['Remix', 'Astro'])
    const data = new FormData(document.querySelector('#stack') as HTMLFormElement)
    assert.deepEqual(data.getAll('frameworks'), ['Remix', 'Astro'])
    await triggerEvent(combobox.input!, 'mousedown', { button: 0 })
    await focus(combobox.input!)
    await a11yAudit()
  })
})
