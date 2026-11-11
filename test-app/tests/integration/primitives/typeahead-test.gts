import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { blur, focus, render } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  Typeahead,
  getNextMatch,
  isTypeaheadKey,
  typeahead,
} from '@ember-joinery/primitives/typeahead'
import { RovingFocusGroup } from '@ember-joinery/primitives/roving-focus'
import { RovingFocusGroupHarness, pressKey, typeKeys } from '@ember-joinery/test-support'

const FRUIT = ['Apple', 'Banana', 'Blueberry', 'Cherry', 'blackcurrant']

function wait(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms))
}

function focusedText(): string {
  return (document.activeElement?.textContent ?? '').trim()
}

module('Integration | primitives | typeahead', function (hooks) {
  setupRenderingTest(hooks)

  test('getNextMatch finds the next item starting with the search, as Radix does', async function (assert) {
    await render(
      <template>
        <p>Matching only.</p>
      </template>,
    )
    assert.strictEqual(getNextMatch(FRUIT, 'b'), 'Banana', 'from nothing, the first match')
    assert.strictEqual(getNextMatch(FRUIT, 'b', 'Banana'), 'Blueberry', 'one letter moves on')
    assert.strictEqual(getNextMatch(FRUIT, 'b', 'blackcurrant'), 'Banana', 'and wraps round')
    assert.strictEqual(getNextMatch(FRUIT, 'BL', 'Banana'), 'Blueberry', 'ignoring case')
    assert.strictEqual(
      getNextMatch(FRUIT, 'bl', 'Blueberry'),
      undefined,
      'a longer search can stay on the current item, so nothing moves',
    )
    assert.strictEqual(getNextMatch(FRUIT, 'bla', 'Blueberry'), 'blackcurrant')
    assert.strictEqual(
      getNextMatch(FRUIT, 'bbb', 'Banana'),
      'Blueberry',
      'one letter repeated cycles through the items with it',
    )
    assert.strictEqual(getNextMatch(FRUIT, 'z'), undefined)
    assert.strictEqual(
      getNextMatch(['Apple'], 'a', 'Apple'),
      undefined,
      'the only match is current',
    )

    const items = [{ label: 'One' }, { label: 'Two' }, { label: 'Three' }]
    assert.strictEqual(
      getNextMatch(items, 't', items[1], item => item.label),
      items[2],
      'with textOf, any items',
    )
    await a11yAudit()
  })

  test('isTypeaheadKey: one printable character, with no Ctrl, Alt or Meta', async function (assert) {
    await render(
      <template>
        <p>Keys only.</p>
      </template>,
    )
    const key = (k: string, mods: Partial<KeyboardEvent> = {}) =>
      isTypeaheadKey({ key: k, ctrlKey: false, altKey: false, metaKey: false, ...mods })
    assert.true(key('a'))
    assert.true(key('A'), 'Shift for capitals is fine')
    assert.true(key(' '))
    assert.false(key('ArrowDown'))
    assert.false(key('a', { ctrlKey: true }))
    assert.false(key('a', { metaKey: true }))
    assert.false(key('a', { altKey: true }))
    await a11yAudit()
  })

  test('Typeahead keeps what was typed until its timeout passes', async function (assert) {
    await render(
      <template>
        <p>Search only.</p>
      </template>,
    )
    const search = new Typeahead({ timeout: 30 })
    assert.false(search.isTyping)
    assert.strictEqual(search.type('b'), 'b')
    assert.strictEqual(search.type('a'), 'ba')
    assert.true(search.isTyping)
    await wait(60)
    assert.strictEqual(search.search, '', 'cleared after the timeout')
    search.type('c')
    search.reset()
    assert.strictEqual(search.search, '')
    search.dispose()
    await a11yAudit()
  })

  test('{{typeahead}} moves focus to the item whose text starts with what is typed', async function (assert) {
    await render(
      <template>
        <div id="list" role="listbox" aria-label="Fruit" {{typeahead}}>
          <div role="option" aria-selected="false" tabindex="-1">Apple</div>
          <div role="option" aria-selected="false" tabindex="-1">Banana</div>
          <div
            role="option"
            aria-selected="false"
            tabindex="-1"
            aria-disabled="true"
          >Blackberry</div>
          <div role="option" aria-selected="false" tabindex="-1">Blueberry</div>
          <div role="option" aria-selected="false" tabindex="-1"> Cherry </div>
        </div>
      </template>,
    )
    await focus('[role="option"]')
    await typeKeys('b')
    assert.strictEqual(focusedText(), 'Banana')
    await typeKeys('l')
    assert.strictEqual(focusedText(), 'Blueberry', '"bl", past the disabled Blackberry')
    await typeKeys('C')
    assert.strictEqual(focusedText(), 'Blueberry', '"blc" matches nothing, so focus stays')

    await blur()
    await focus('[role="option"]')
    await typeKeys('ch')
    assert.strictEqual(focusedText(), 'Cherry', 'focus leaving cleared the search; text is trimmed')
    await a11yAudit()
  })

  test('the search clears a moment after the last key', async function (assert) {
    await render(
      <template>
        <div role="listbox" aria-label="Fruit" {{typeahead timeout=30}}>
          <div role="option" aria-selected="false" tabindex="-1">Apple</div>
          <div role="option" aria-selected="false" tabindex="-1">Banana</div>
          <div role="option" aria-selected="false" tabindex="-1">Avocado</div>
        </div>
      </template>,
    )
    await focus('[role="option"]')
    await typeKeys('b')
    assert.strictEqual(focusedText(), 'Banana')
    await wait(60)
    await typeKeys('a')
    assert.strictEqual(focusedText(), 'Avocado', 'a new search, "a", not "ba"')
    await a11yAudit()
  })

  test('while a search is under way, Space is part of it and presses nothing', async function (assert) {
    await render(
      <template>
        <div role="menu" aria-label="Actions" {{typeahead}}>
          <button type="button" role="menuitem">New tab</button>
          <button type="button" role="menuitem">New window</button>
          <button type="button" role="menuitem">Print</button>
        </div>
      </template>,
    )
    await focus('[role="menuitem"]')
    assert.false(await pressKey(' '), 'a Space on its own presses the item')
    await typeKeys('new')
    assert.true(await pressKey(' '), 'during a search, Space is prevented')
    await typeKeys('w')
    assert.strictEqual(focusedText(), 'New window', '"new w"')
    await a11yAudit()
  })

  test("it hears keys before the items do, so an item's own Space handler sees the search", async function (assert) {
    const seen: boolean[] = []
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === ' ') seen.push(event.defaultPrevented)
    }
    await render(
      <template>
        <div role="listbox" aria-label="Fruit" {{typeahead}}>
          <div role="option" aria-selected="false" tabindex="-1" {{on "keydown" onKeyDown}}>
            Passion fruit
          </div>
          <div role="option" aria-selected="false" tabindex="-1" {{on "keydown" onKeyDown}}>
            Pear
          </div>
        </div>
      </template>,
    )
    await focus('[role="option"]')
    await pressKey(' ')
    await typeKeys('pa')
    await pressKey(' ')
    assert.deepEqual(seen, [false, true], 'prevented only while a search is under way')
    await a11yAudit()
  })

  test('items, textValue, onMatch and disabled change what it searches and does', async function (assert) {
    const matches: string[] = []
    const onMatch = (item: HTMLElement) => matches.push(item.id)
    const items = () => [...document.querySelectorAll<HTMLElement>('#custom [data-item]')]
    const textValue = (item: HTMLElement) => item.dataset['label'] ?? ''
    await render(
      <template>
        <div
          id="custom"
          role="group"
          aria-label="Custom"
          {{typeahead items=items textValue=textValue onMatch=onMatch}}
        >
          <button id="first" type="button">Start</button>
          <span id="x" data-item data-label="Xylophone">🎵</span>
          <span id="y" data-item data-label="Yak">🐂</span>
        </div>
        <div id="off" role="group" aria-label="Off" {{typeahead disabled=true}}>
          <button id="off-a" type="button">Alpha</button>
          <button id="off-b" type="button">Beta</button>
        </div>
      </template>,
    )
    await focus('#first')
    await typeKeys('y')
    assert.deepEqual(matches, ['y'], 'onMatch hears the match, by its textValue')
    assert.dom('#first').isFocused('and focus is left to it')

    await focus('#off-a')
    await typeKeys('b')
    assert.dom('#off-a').isFocused('disabled: nothing happens')
    await a11yAudit()
  })

  test('with a roving focus group: arrows move, and so does typing', async function (assert) {
    await render(
      <template>
        <RovingFocusGroup
          @name="menu"
          @orientation="vertical"
          role="menu"
          aria-label="File"
          {{typeahead}}
          as |group|
        >
          <group.Item @tabStopId="open" role="menuitem">Open</group.Item>
          <group.Item @tabStopId="save" role="menuitem">Save</group.Item>
          <group.Item @tabStopId="share" role="menuitem">Share</group.Item>
        </RovingFocusGroup>
      </template>,
    )
    const menu = new RovingFocusGroupHarness('menu')
    await menu.focus('open')
    await typeKeys('sh')
    assert.strictEqual(menu.focused, 'share')
    assert.strictEqual(menu.tabStop, 'share', 'the tab stop follows')
    await menu.press('ArrowUp')
    assert.strictEqual(menu.focused, 'save')
    await a11yAudit()
  })
})
