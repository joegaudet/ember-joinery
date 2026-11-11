import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, focus, render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { array, fn } from '@ember/helper'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  Command,
  CommandDialog,
  defaultFilter,
  matchesHotkey,
} from '@ember-joinery/primitives/command'
import {
  CommandDialogHarness,
  CommandHarness,
  pressEscape,
  pressKey,
} from '@ember-joinery/test-support'

const SUGGESTIONS = ['Calendar', 'Search Emoji', 'Calculator']
const SETTINGS = ['Profile', 'Billing', 'Settings']

class Choices {
  values: string[] = []
  events: Event[] = []
  choose = (value: string, event?: Event) => {
    this.values.push(value)
    if (event) this.events.push(event)
  }
}

module('Integration | primitives | command', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders cmdk's anatomy, with the first item selected", async function (assert) {
    await render(
      <template>
        <Command @name="menu" as |c|>
          <c.Input placeholder="Type a command or search..." />
          <c.List>
            <c.Empty>No results found.</c.Empty>
            <c.Group @heading="Suggestions">
              {{#each SUGGESTIONS as |label|}}
                <c.Item>{{label}}</c.Item>
              {{/each}}
            </c.Group>
            <c.Separator />
            <c.Group @heading="Settings">
              {{#each SETTINGS as |label|}}
                <c.Item>{{label}}</c.Item>
              {{/each}}
            </c.Group>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness('menu')
    assert
      .dom(command.element)
      .hasAttribute('cmdk-root', '')
      .hasAttribute('tabindex', '-1')
      .hasAttribute('data-test-jn', 'command')
    assert
      .dom(command.input)
      .hasTagName('input')
      .hasAttribute('type', 'text')
      .hasAttribute('role', 'combobox')
      .hasAttribute('aria-autocomplete', 'list')
      .hasAttribute('aria-expanded', 'true')
      .hasAttribute('aria-controls', command.list.id)
      .hasAttribute('autocomplete', 'off')
      .hasAttribute('spellcheck', 'false')
      .hasAttribute('cmdk-input', '')
      .doesNotHaveAttribute('aria-labelledby', 'no @label, so nothing labels it')
    assert
      .dom(command.list)
      .hasAttribute('role', 'listbox')
      .hasAttribute('tabindex', '-1')
      .hasAttribute('aria-label', 'Suggestions')
      .hasAttribute('cmdk-list', '')
    assert.dom('[cmdk-list-sizer]', command.list).exists()

    assert.deepEqual(command.itemValues, [...SUGGESTIONS, ...SETTINGS], 'values are their text')
    for (const item of command.items) {
      assert.dom(item).hasAttribute('role', 'option').hasAttribute('cmdk-item', '')
      assert.dom(item).hasAttribute('aria-disabled', 'false').hasAttribute('data-disabled', 'false')
    }
    assert.deepEqual(command.headings, ['Suggestions', 'Settings'])
    const [group] = command.groups
    assert.dom(group).hasAttribute('role', 'presentation').hasAttribute('cmdk-group', '')
    const heading = group!.querySelector('[cmdk-group-heading]')!
    assert.dom(heading).hasAttribute('aria-hidden', 'true').hasText('Suggestions')
    assert
      .dom('[cmdk-group-items]', group)
      .hasAttribute('role', 'group')
      .hasAttribute('aria-labelledby', heading.id)
    assert.strictEqual(command.separators.length, 1)
    assert
      .dom(command.separators[0])
      .hasAttribute('role', 'separator')
      .hasAttribute('aria-hidden', 'true', 'a listbox holds only options and groups')
    assert.false(command.isEmpty)
    assert.strictEqual(command.status, '6 results')
    assert.dom(command.part('status')).hasAttribute('role', 'status')

    assert.strictEqual(command.selected, 'Calendar', 'the first item is selected')
    assert
      .dom(command.item('Calendar'))
      .hasAttribute('aria-selected', 'true')
      .hasAttribute('data-selected', 'true')
    assert.dom(command.item('Profile')).hasAttribute('aria-selected', 'false')
    assert.strictEqual(command.activeItem, command.item('Calendar'))
    assert.dom(command.list).hasAttribute('aria-activedescendant', command.item('Calendar').id)
    await a11yAudit()
  })

  test('@label names the input with a visually hidden label', async function (assert) {
    await render(
      <template>
        <Command @label="Command Menu" as |c|>
          <c.Input />
          <c.List><c.Item>Apple</c.Item></c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness()
    const label = command.part('label')
    assert
      .dom(label)
      .hasTagName('label')
      .hasText('Command Menu')
      .hasAttribute('for', command.input.id)
    assert.dom(command.input).hasAttribute('aria-labelledby', label.id)
    assert.strictEqual(getComputedStyle(label).position, 'absolute', 'visually hidden')
    await a11yAudit()
  })

  test('typing filters the items and ranks the best first', async function (assert) {
    await render(
      <template>
        <Command as |c|>
          <c.Input aria-label="Search" />
          <c.List>
            <c.Empty>No results found.</c.Empty>
            <c.Group @heading="Suggestions">
              {{#each SUGGESTIONS as |label|}}
                <c.Item>{{label}}</c.Item>
              {{/each}}
            </c.Group>
            <c.Separator />
            <c.Group @heading="Settings">
              {{#each SETTINGS as |label|}}
                <c.Item>{{label}}</c.Item>
              {{/each}}
            </c.Group>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness()

    await command.search('e')
    assert.deepEqual(
      command.itemValues,
      ['Search Emoji', 'Calendar', 'Profile', 'Settings'],
      "cmdk's ranking: the start of a word (Emoji) beats a letter inside one",
    )
    assert.deepEqual(command.groupValues('Suggestions'), ['Search Emoji', 'Calendar'])
    assert.strictEqual(command.separators.length, 0, 'separators hide during a search')
    assert.strictEqual(command.selected, 'Search Emoji', 'the best match is selected')
    assert.strictEqual(command.status, '4 results')
    assert
      .dom(command.items[0])
      .hasAttribute('aria-posinset', '1')
      .hasAttribute('aria-setsize', '4')
    assert.false(command.hasItem('Billing'), 'what the search hides is not rendered')
    await a11yAudit()

    await command.search('cal')
    assert.deepEqual(command.itemValues, ['Calendar', 'Calculator'])
    assert.deepEqual(command.headings, ['Suggestions'], 'a group with nothing left hides')
    assert.true(command.parts('group')[1]!.hidden)

    await command.search('xyz')
    assert.true(command.isEmpty)
    assert.dom(command.empty).hasText('No results found.').hasAttribute('role', 'presentation')
    assert
      .dom(command.list)
      .doesNotHaveAttribute(
        'role',
        'a listbox holds options; with none to show, it is a plain element',
      )
      .doesNotHaveAttribute('aria-label')
    assert.strictEqual(command.status, '0 results')
    assert.strictEqual(command.selected, null)
    assert.dom(command.input).doesNotHaveAttribute('aria-activedescendant')
    await a11yAudit()

    await command.clear()
    assert.deepEqual(command.itemValues, [...SUGGESTIONS, ...SETTINGS], 'back in their own order')
    assert.strictEqual(command.separators.length, 1)
    assert.strictEqual(command.status, '6 results')
    assert.strictEqual(command.selected, 'Calendar')
    for (const item of command.items) {
      assert.strictEqual(item.style.order, '', 'no order left behind')
      assert.dom(item).doesNotHaveAttribute('aria-posinset')
    }
  })

  test('groups show by their best item, after the items outside a group', async function (assert) {
    await render(
      <template>
        <Command as |c|>
          <c.Input aria-label="Search" />
          <c.List>
            <c.Group @heading="Fruit">
              <c.Item>Pineapple</c.Item>
              <c.Item>Apple</c.Item>
            </c.Group>
            <c.Group @heading="Tools">
              <c.Item>Hammer</c.Item>
              <c.Item>App</c.Item>
            </c.Group>
            <c.Item>Appendix</c.Item>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness()
    await command.search('app')
    assert.deepEqual(command.itemValues, ['Appendix', 'App', 'Apple', 'Pineapple'])
    assert.deepEqual(command.headings, ['Tools', 'Fruit'])
    assert.strictEqual(command.selected, 'Appendix')
    await command.press('ArrowDown')
    assert.strictEqual(command.selected, 'App', 'the keys follow the order they show in')
    await command.press('ArrowDown', { altKey: true })
    assert.strictEqual(command.selected, 'Apple', 'and so does Alt')
    await a11yAudit()

    await command.clear()
    assert.deepEqual(command.itemValues, ['Pineapple', 'Apple', 'Hammer', 'App', 'Appendix'])
    assert.deepEqual(command.headings, ['Fruit', 'Tools'])
  })

  test('the default filter is cmdk’s', function (assert) {
    assert.strictEqual(
      defaultFilter('Calendar', 'calendar', []),
      1 * 0.9999 ** 1,
      'case costs a little',
    )
    assert.strictEqual(defaultFilter('apple', 'apple', []), 1)
    assert.strictEqual(defaultFilter('apple', 'xyz', []), 0)
    assert.true(defaultFilter('Search Emoji', 'e', []) > defaultFilter('Calendar', 'e', []))
    assert.true(defaultFilter('Apple', 'fruit', ['fruit']) > 0, 'keywords match too')
    assert.true(defaultFilter('cut-paste', 'cp', []) > defaultFilter('accept', 'cp', []))
  })

  test('keyboard: the arrows, Home and End move the selection; disabled items are passed over', async function (assert) {
    const choices = new Choices()
    await render(
      <template>
        <Command @onSelect={{choices.choose}} as |c|>
          <c.Input aria-label="Search" />
          <c.List>
            <c.Item>Apple</c.Item>
            <c.Item @disabled={{true}}>Banana</c.Item>
            <c.Item>Cherry</c.Item>
            <c.Item>Date</c.Item>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness()
    assert.strictEqual(command.selected, 'Apple')
    assert.true(command.isDisabled('Banana'))
    assert.dom(command.item('Banana')).hasAttribute('data-disabled', 'true')

    await command.press('ArrowDown')
    assert.strictEqual(command.selected, 'Cherry', 'past the disabled one')
    assert.true(command.hasFocus, 'focus stays in the input')
    assert.strictEqual(command.activeItem, command.item('Cherry'))
    await command.press('ArrowDown')
    assert.strictEqual(command.selected, 'Date')
    await command.press('ArrowDown')
    assert.strictEqual(command.selected, 'Date', 'no wrapping without @loop')
    await command.press('ArrowUp')
    assert.strictEqual(command.selected, 'Cherry')
    await command.press('Home')
    assert.strictEqual(command.selected, 'Apple')
    await command.press('End')
    assert.strictEqual(command.selected, 'Date')
    await command.press('ArrowUp', { metaKey: true })
    assert.strictEqual(command.selected, 'Apple', '⌘↑ to the first')
    await command.press('ArrowDown', { metaKey: true })
    assert.strictEqual(command.selected, 'Date', '⌘↓ to the last')

    await command.press('Enter')
    assert.deepEqual(choices.values, ['Date'], 'Enter chooses the selected item')
    assert.true(choices.events[0] instanceof MouseEvent, 'as a click')
    await a11yAudit()
  })

  test('the Vim keys, @loop and @vimBindings', async function (assert) {
    class State {
      @tracked vim = true
    }
    const state = new State()
    await render(
      <template>
        <Command @loop={{true}} @vimBindings={{state.vim}} as |c|>
          <c.Input aria-label="Search" />
          <c.List>
            <c.Item>Apple</c.Item>
            <c.Item>Banana</c.Item>
            <c.Item>Cherry</c.Item>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness()
    await command.press('ArrowUp')
    assert.strictEqual(command.selected, 'Cherry', '@loop wraps round to the last')
    await command.press('ArrowDown')
    assert.strictEqual(command.selected, 'Apple', 'and back to the first')
    await command.press('n', { ctrlKey: true })
    assert.strictEqual(command.selected, 'Banana', 'Ctrl+N')
    await command.press('j', { ctrlKey: true })
    assert.strictEqual(command.selected, 'Cherry', 'Ctrl+J')
    await command.press('p', { ctrlKey: true })
    assert.strictEqual(command.selected, 'Banana', 'Ctrl+P')
    await command.press('k', { ctrlKey: true })
    assert.strictEqual(command.selected, 'Apple', 'Ctrl+K')
    await command.press('n')
    assert.strictEqual(command.selected, 'Apple', 'n alone is a letter')

    state.vim = false
    await settled()
    await command.press('n', { ctrlKey: true })
    assert.strictEqual(command.selected, 'Apple', 'off with @vimBindings={{false}}')
    await a11yAudit()
  })

  test('Alt and an arrow jump to the next or previous group', async function (assert) {
    await render(
      <template>
        <Command as |c|>
          <c.Input aria-label="Search" />
          <c.List>
            <c.Group @heading="Fruit">
              <c.Item>Apple</c.Item>
              <c.Item>Banana</c.Item>
            </c.Group>
            <c.Group @heading="Vegetables">
              <c.Item>Carrot</c.Item>
              <c.Item>Daikon</c.Item>
            </c.Group>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness()
    await command.press('ArrowDown', { altKey: true })
    assert.strictEqual(command.selected, 'Carrot')
    await command.press('ArrowDown')
    await command.press('ArrowUp', { altKey: true })
    assert.strictEqual(command.selected, 'Apple')
    await a11yAudit()
  })

  test('while an input method composes, the keys are its own', async function (assert) {
    await render(
      <template>
        <Command as |c|>
          <c.Input aria-label="Search" />
          <c.List>
            <c.Item>Apple</c.Item>
            <c.Item>Banana</c.Item>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness()
    await focus(command.input)
    command.input.dispatchEvent(
      new KeyboardEvent('keydown', { key: 'ArrowDown', isComposing: true, bubbles: true }),
    )
    await settled()
    assert.strictEqual(command.selected, 'Apple')
    await a11yAudit()
  })

  test('the pointer selects what it moves over, and a click chooses', async function (assert) {
    const choices = new Choices()
    const own = new Choices()
    await render(
      <template>
        <Command @onSelect={{choices.choose}} as |c|>
          <c.Input aria-label="Search" />
          <c.List>
            <c.Item>Apple</c.Item>
            <c.Item @disabled={{true}} @onSelect={{own.choose}}>Banana</c.Item>
            <c.Item @value="cherry" @onSelect={{own.choose}}>Cherry</c.Item>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness()
    await command.hover('cherry')
    assert.strictEqual(command.selected, 'cherry')
    await command.hover('Banana')
    assert.strictEqual(command.selected, 'cherry', 'not a disabled item')
    await command.choose('Banana')
    assert.deepEqual(own.values, [], 'nor does a click choose it')

    await command.choose('cherry')
    assert.deepEqual(own.values, ['cherry'], "the item's @onSelect, with its @value")
    assert.deepEqual(choices.values, ['cherry'], "and the command's")
    assert.true(choices.events[0] instanceof MouseEvent)
    await a11yAudit()
  })

  test('@disablePointerSelection leaves the selection to the keys', async function (assert) {
    await render(
      <template>
        <Command @disablePointerSelection={{true}} as |c|>
          <c.Input aria-label="Search" />
          <c.List>
            <c.Item>Apple</c.Item>
            <c.Item>Banana</c.Item>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness()
    await command.hover('Banana')
    assert.strictEqual(command.selected, 'Apple')
    await a11yAudit()
  })

  test('controlled: @value and @onValueChange, @search and @onSearchChange', async function (assert) {
    class State {
      @tracked value = 'Banana'
      @tracked search = ''
      values: string[] = []
      searches: string[] = []
      setValue = (value: string) => {
        this.values.push(value)
        this.value = value
      }
      setSearch = (search: string) => {
        this.searches.push(search)
        this.search = search.toLowerCase()
      }
    }
    const state = new State()
    await render(
      <template>
        <Command
          @value={{state.value}}
          @onValueChange={{state.setValue}}
          @search={{state.search}}
          @onSearchChange={{state.setSearch}}
          as |c|
        >
          <c.Input aria-label="Search" />
          <c.List>
            <c.Item>Apple</c.Item>
            <c.Item>Banana</c.Item>
            <c.Item>Cherry</c.Item>
          </c.List>
          <output data-test-search>{{c.search}}</output>
          <output data-test-value>{{c.value}}</output>
        </Command>
      </template>,
    )
    const command = new CommandHarness()
    assert.strictEqual(command.selected, 'Banana')
    assert.dom('[data-test-value]').hasText('Banana')

    await command.press('ArrowDown')
    assert.deepEqual(state.values, ['Cherry'])
    assert.strictEqual(command.selected, 'Cherry')

    state.value = 'Apple'
    await settled()
    assert.strictEqual(command.selected, 'Apple', 'it follows @value')

    await command.search('CH')
    assert.deepEqual(state.searches, ['CH'])
    assert.strictEqual(command.query, 'ch', 'the input shows the search you keep')
    assert.dom('[data-test-search]').hasText('ch')
    assert.deepEqual(command.itemValues, ['Cherry'])
    assert.strictEqual(command.selected, 'Cherry')

    state.search = ''
    await settled()
    assert.strictEqual(command.query, '')
    assert.strictEqual(command.itemValues.length, 3)
    await a11yAudit()
  })

  test('@defaultSearch and @defaultValue', async function (assert) {
    await render(
      <template>
        <Command @defaultSearch="b" as |c|>
          <c.Input aria-label="Search" />
          <c.List>
            <c.Item>Apple</c.Item>
            <c.Item>Banana</c.Item>
            <c.Item>Blueberry</c.Item>
          </c.List>
        </Command>
        <Command @defaultValue="Cherry" @name="value" as |c|>
          <c.Input aria-label="Other search" />
          <c.List @label="Other suggestions">
            <c.Item>Apple</c.Item>
            <c.Item>Cherry</c.Item>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness()
    assert.strictEqual(command.query, 'b')
    assert.deepEqual(command.itemValues, ['Banana', 'Blueberry'], 'it starts filtered')
    assert.strictEqual(command.selected, 'Banana')
    assert.strictEqual(new CommandHarness('value').selected, 'Cherry')
    await a11yAudit()
  })

  test('@value, @keywords, @filter and @shouldFilter', async function (assert) {
    const startsWith = (value: string, search: string) =>
      value.toLowerCase().startsWith(search.toLowerCase()) ? 1 : 0
    await render(
      <template>
        <Command @name="keywords" as |c|>
          <c.Input aria-label="Keywords" />
          <c.List @label="Fruit">
            <c.Item @value="apple" @keywords={{array "fruit" " red "}}>Apple</c.Item>
            <c.Item @value="  carrot  ">Carrot</c.Item>
          </c.List>
        </Command>
        <Command @name="filter" @filter={{startsWith}} as |c|>
          <c.Input aria-label="Filter" />
          <c.List @label="Starts with">
            <c.Item>Banana</c.Item>
            <c.Item>Cabbage</c.Item>
          </c.List>
        </Command>
        <Command @name="unfiltered" @shouldFilter={{false}} as |c|>
          <c.Input aria-label="Unfiltered" />
          <c.List @label="All">
            <c.Item>Banana</c.Item>
            <c.Item>Cabbage</c.Item>
          </c.List>
        </Command>
      </template>,
    )
    const keywords = new CommandHarness('keywords')
    assert.deepEqual(keywords.itemValues, ['apple', 'carrot'], 'values are trimmed')
    await keywords.search('red')
    assert.deepEqual(keywords.itemValues, ['apple'], 'a keyword matches')

    const filter = new CommandHarness('filter')
    await filter.search('a')
    assert.deepEqual(
      filter.itemValues,
      [],
      "cmdk's filter would match both; this one matches neither",
    )
    await filter.search('ca')
    assert.deepEqual(filter.itemValues, ['Cabbage'])

    const unfiltered = new CommandHarness('unfiltered')
    await unfiltered.search('zzz')
    assert.deepEqual(unfiltered.itemValues, ['Banana', 'Cabbage'], 'nothing is filtered')
    assert.strictEqual(unfiltered.status, '2 results')
    await a11yAudit()
  })

  test('@forceMount items and groups, and @alwaysRender separators', async function (assert) {
    await render(
      <template>
        <Command as |c|>
          <c.Input aria-label="Search" />
          <c.List>
            <c.Empty>No results found.</c.Empty>
            <c.Group @heading="Always" @forceMount={{true}}>
              <c.Item @forceMount={{true}}>Help</c.Item>
            </c.Group>
            <c.Separator @alwaysRender={{true}} />
            <c.Item>Apple</c.Item>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness()
    assert.strictEqual(command.status, '1 result', 'a forced item is not a result')
    await command.search('apple')
    assert.deepEqual(
      command.itemValues,
      ['Help', 'Apple'],
      'it shows, and its group keeps its place ahead of the ranked items, as in cmdk',
    )
    assert.deepEqual(command.headings, ['Always'])
    assert.strictEqual(command.separators.length, 1)
    await command.search('zzz')
    assert.true(command.isEmpty)
    assert.deepEqual(command.itemValues, ['Help'])
    await a11yAudit()
  })

  test('items can come, go and change their text', async function (assert) {
    class State {
      @tracked fruit = ['Apple', 'Banana']
      @tracked label = 'Cherry'
    }
    const state = new State()
    await render(
      <template>
        <Command as |c|>
          <c.Input aria-label="Search" />
          <c.List>
            {{#each state.fruit as |fruit|}}
              <c.Item>{{fruit}}</c.Item>
            {{/each}}
            <c.Item>{{state.label}}</c.Item>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness()
    assert.strictEqual(command.status, '3 results')

    state.fruit = ['Apricot', 'Apple', 'Banana']
    await settled()
    assert.deepEqual(command.itemValues, ['Apricot', 'Apple', 'Banana', 'Cherry'])
    assert.strictEqual(command.status, '4 results')

    state.label = 'Date'
    await settled()
    await command.search('date')
    assert.deepEqual(command.itemValues, ['Date'], 'it searches the new text')

    await command.clear()
    assert.strictEqual(command.selected, 'Apricot')
    state.fruit = ['Banana']
    await settled()
    assert.strictEqual(command.selected, 'Banana', 'the selected item went, so the first is')
    await a11yAudit()
  })

  test('@resultsText says the count in your words', async function (assert) {
    const resultsText = (count: number) => `${count} résultats`
    await render(
      <template>
        <Command @resultsText={{resultsText}} as |c|>
          <c.Input aria-label="Rechercher" />
          <c.List @label="Suggestions">
            <c.Item>Pomme</c.Item>
            <c.Item>Poire</c.Item>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness()
    assert.strictEqual(command.status, '2 résultats')
    await command.search('pom')
    assert.strictEqual(command.status, '1 résultats')
    await a11yAudit()
  })

  test('@hotkey calls @onOpen from anywhere on the page', async function (assert) {
    class State {
      opened = 0
      open = () => this.opened++
    }
    const state = new State()
    await render(
      <template>
        <button type="button">Elsewhere</button>
        <Command @hotkey="mod+k" @onOpen={{state.open}} as |c|>
          <c.Input aria-label="Search" />
          <c.List><c.Item>Apple</c.Item></c.List>
        </Command>
      </template>,
    )
    const palette = new CommandDialogHarness()
    await focus('button')
    await palette.pressHotkey('mod+k')
    assert.strictEqual(state.opened, 1)
    await palette.pressHotkey('shift+mod+k')
    assert.strictEqual(state.opened, 1, 'every other modifier must be up')

    const event = new KeyboardEvent('keydown', { key: 'k', ctrlKey: true, metaKey: true })
    assert.false(matchesHotkey(event, 'mod+k'), 'only the platform’s mod key')
    assert.true(matchesHotkey(new KeyboardEvent('keydown', { key: 'K', altKey: true }), 'alt+k'))
    await a11yAudit()
  })

  test('an item that is a link: Enter clicks it, and a modified click leaves the command be', async function (assert) {
    const choices = new Choices()
    const stay = (event: Event) => event.preventDefault()
    await render(
      <template>
        <Command @onSelect={{choices.choose}} as |c|>
          <c.Input aria-label="Search" />
          <c.List {{on "click" stay}}>
            <c.Item @as="a" href="#settings">Settings</c.Item>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness()
    assert.dom(command.item('Settings')).hasTagName('a').hasAttribute('role', 'option')

    let clicks = 0
    command.item('Settings').addEventListener('click', () => clicks++)
    await command.press('Enter')
    assert.strictEqual(clicks, 1, 'Enter is a real click on the link')
    assert.deepEqual(choices.values, ['Settings'])

    await click(command.item('Settings'), { metaKey: true })
    assert.deepEqual(choices.values, ['Settings'], 'a ⌘-click opens it elsewhere')
    await a11yAudit()
  })

  test('focus on the root goes back to the input when the selection moves', async function (assert) {
    await render(
      <template>
        <Command as |c|>
          <c.Input aria-label="Search" />
          <c.List>
            <c.Item>Apple</c.Item>
            <c.Item>Banana</c.Item>
          </c.List>
        </Command>
      </template>,
    )
    const command = new CommandHarness()
    await focus(command.element)
    await pressKey('ArrowDown')
    assert.strictEqual(command.selected, 'Banana')
    assert.true(command.hasFocus)
    await a11yAudit()
  })

  test('RTL: the keys are the same, up and down', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Command as |c|>
            <c.Input aria-label="بحث" />
            <c.List @label="اقتراحات">
              <c.Item>التقويم</c.Item>
              <c.Item>الآلة الحاسبة</c.Item>
            </c.List>
          </Command>
        </DirectionProvider>
      </template>,
    )
    const command = new CommandHarness()
    assert.strictEqual(getComputedStyle(command.element).direction, 'rtl')
    await command.press('ArrowDown')
    assert.strictEqual(command.selected, 'الآلة الحاسبة')
    await command.press('ArrowLeft')
    assert.strictEqual(command.selected, 'الآلة الحاسبة', 'the inline arrows stay with the caret')
    await a11yAudit()
  })

  test('CommandDialog: a command in a modal dialog, opened and closed by its hotkey', async function (assert) {
    const choices = new Choices()
    await render(
      <template>
        <button type="button">Before</button>
        <CommandDialog @hotkey="mod+k" @name="palette" as |d|>
          <Command @onSelect={{fn d.setOpen false}} as |c|>
            <c.Input placeholder="Type a command or search..." />
            <c.List>
              <c.Item @onSelect={{choices.choose}}>Calendar</c.Item>
              <c.Item>Calculator</c.Item>
            </c.List>
          </Command>
        </CommandDialog>
      </template>,
    )
    const palette = new CommandDialogHarness('palette')
    assert.false(palette.isOpen)
    assert.strictEqual(palette.content, null)

    await focus('button')
    await palette.pressHotkey('mod+k')
    assert.true(palette.isOpen)
    assert.true(palette.isModal)
    assert.true(palette.isInTopLayer)
    assert.strictEqual(palette.label, 'Command Palette')
    assert.strictEqual(palette.descriptionText, 'Search for a command to run...')
    assert.dom(palette.content).hasAttribute('cmdk-dialog', '')
    assert.dom(palette.overlay).hasAttribute('cmdk-overlay', '')
    assert.true(palette.command.hasFocus, 'focus moves into the input')
    await a11yAudit()

    await palette.command.search('calc')
    await palette.command.press('Enter')
    assert.false(palette.isOpen, 'choosing closes it')
    assert.dom('button').isFocused('focus goes back')

    await palette.pressHotkey('mod+k')
    await palette.command.press('Enter')
    assert.deepEqual(choices.values, ['Calendar'])

    await palette.pressHotkey('mod+k')
    assert.true(palette.isOpen)
    await palette.pressHotkey('mod+k')
    assert.false(palette.isOpen, 'the hotkey closes it too')

    await palette.pressHotkey('mod+k')
    await pressEscape()
    assert.false(palette.isOpen, 'Escape closes it')
    await a11yAudit()
  })

  test('CommandDialog: controlled, with a title and description of your own', async function (assert) {
    class State {
      @tracked open = false
      setOpen = (open: boolean) => (this.open = open)
    }
    const state = new State()
    await render(
      <template>
        <button type="button" {{on "click" (fn state.setOpen true)}}>Open Menu</button>
        <CommandDialog
          @open={{state.open}}
          @onOpenChange={{state.setOpen}}
          @title="Palette"
          @description="Run a command"
          @overlayClass="backdrop"
          class="palette"
        >
          <Command as |c|>
            <c.Input aria-label="Search" />
            <c.List><c.Item>Apple</c.Item></c.List>
          </Command>
        </CommandDialog>
      </template>,
    )
    await click('button')
    const palette = new CommandDialogHarness()
    assert.true(palette.isOpen)
    assert.strictEqual(palette.label, 'Palette')
    assert.strictEqual(palette.descriptionText, 'Run a command')
    assert.dom(palette.content).hasClass('palette', 'its attributes go on the dialog')
    assert.dom(palette.overlay).hasClass('backdrop', '@overlayClass on the overlay')
    await palette.pressEscape()
    assert.false(state.open)
    assert.dom('button').isFocused()
    await a11yAudit()
  })
})
