import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { find, focus, getRootElement, render } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { pressKey, tab, tabOrder, typeKeys } from '@ember-joinery/test-support'

function ids(elements: Element[]): string[] {
  return elements.map(element => element.id)
}

module('Integration | test-support | focus', function (hooks) {
  setupRenderingTest(hooks)

  test('tabOrder lists what the Tab key visits, in the order a browser visits it', async function (assert) {
    await render(
      <template>
        <button id="a" type="button">A</button>
        <button id="skipped" type="button" tabindex="-1">Skipped</button>
        <button id="disabled" type="button" disabled>Disabled</button>
        <a id="no-href">Not a link</a>
        <a id="link" href="#here">Link</a>
        <div hidden><button id="hidden" type="button">x</button></div>
        <div inert><button id="inert" type="button">x</button></div>
        <details><summary id="summary">More</summary><button
            id="closed"
            type="button"
          >x</button></details>
        <fieldset>
          <legend>Size</legend>
          <label><input id="small" type="radio" name="size" /> Small</label>
          <label><input id="large" type="radio" name="size" checked /> Large</label>
        </fieldset>
        <fieldset>
          <legend>Colour</legend>
          <label><input id="red" type="radio" name="colour" /> Red</label>
          <label><input id="blue" type="radio" name="colour" /> Blue</label>
        </fieldset>
      </template>,
    )
    assert.deepEqual(ids(tabOrder(getRootElement() as Element)), [
      'a',
      'link',
      'summary',
      'large',
      'red',
      'blue',
    ])
    await a11yAudit()
  })

  test('tabOrder puts positive tabindexes first, lowest first', async function (assert) {
    await render(
      <template>
        <p>Positive tabindexes fail the audit, so they stay off the page.</p>
      </template>,
    )
    const container = document.createElement('div')
    container.innerHTML = `
      <button id="zero" type="button">Zero</button>
      <button id="two" type="button" tabindex="2">Two</button>
      <button id="one" type="button" tabindex="1">One</button>
      <button id="also-one" type="button" tabindex="1">Also one</button>`
    ;(getRootElement() as Element).append(container)
    assert.deepEqual(ids(tabOrder(container)), ['one', 'also-one', 'two', 'zero'])
    container.remove()
    await a11yAudit()
  })

  test('tab() moves focus through the tab order, and Shift+Tab back', async function (assert) {
    await render(
      <template>
        <button id="a" type="button">A</button>
        <div id="group" tabindex="-1">
          <button id="b" type="button">B</button>
        </div>
        <button id="c" type="button">C</button>
      </template>,
    )
    await focus('#a')
    await tab()
    assert.dom('#b').isFocused()
    await tab()
    assert.dom('#c').isFocused()
    await tab({ shift: true })
    assert.dom('#b').isFocused()

    await focus('#group')
    await tab()
    assert.dom('#b').isFocused('from an element outside the order, to the next one after it')
    await a11yAudit()
  })

  test('tab() leaves the page after the last element, and respects preventDefault()', async function (assert) {
    const stay = (event: KeyboardEvent) => {
      if (event.key === 'Tab') event.preventDefault()
    }
    await render(
      <template>
        <button id="a" type="button" {{on "keydown" stay}}>A</button>
        <button id="b" type="button">B</button>
      </template>,
    )
    await focus('#a')
    await tab()
    assert.dom('#a').isFocused('the page kept focus where it was')

    const last = tabOrder().at(-1)!
    await focus(last)
    await tab()
    assert.strictEqual(
      document.activeElement,
      document.body,
      'past the last, focus leaves the page',
    )
    await a11yAudit()
  })

  test('pressKey and typeKeys send key events to the focused element', async function (assert) {
    const keys: string[] = []
    const record = (event: KeyboardEvent) => {
      keys.push(`${event.type}:${event.key}${event.shiftKey ? '+shift' : ''}`)
      if (event.key === 'Enter') event.preventDefault()
    }
    await render(
      <template>
        <div id="target" tabindex="0" role="button" {{on "keydown" record}} {{on "keyup" record}}>
          Target
        </div>
      </template>,
    )
    await focus('#target')
    assert.false(await pressKey('ArrowDown'))
    assert.true(await pressKey('Enter'), 'it says when the keydown was prevented')
    await pressKey('Tab', { shiftKey: true })
    assert.dom(find('#target')).isFocused('pressKey sends the key events only')
    await typeKeys('ab')
    assert.deepEqual(keys, [
      'keydown:ArrowDown',
      'keyup:ArrowDown',
      'keydown:Enter',
      'keyup:Enter',
      'keydown:Tab+shift',
      'keyup:Tab+shift',
      'keydown:a',
      'keyup:a',
      'keydown:b',
      'keyup:b',
    ])
    await a11yAudit()
  })
})
