import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { blur, click, find, focus, render, settled } from '@ember/test-helpers'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { focusElement, focusFirst, focusable, restoreFocus } from '@ember-joinery/primitives/focus'

function ids(elements: Element[]): string[] {
  return elements.map(element => element.id)
}

function byId(id: string): HTMLElement {
  return find(`#${id}`) as HTMLElement
}

module('Integration | primitives | focus', function (hooks) {
  setupRenderingTest(hooks)

  test('focusable finds what can take focus, and skips what is hidden, disabled or inert', async function (assert) {
    await render(
      <template>
        <div id="container">
          <button id="button" type="button">Button</button>
          <button id="disabled" type="button" disabled>Disabled</button>
          <input id="input" aria-label="Input" />
          <input id="hidden-input" type="hidden" />
          <a id="link" href="#here">Link</a>
          <a id="no-href">Not a link</a>
          <div id="tabbable-div" tabindex="0">Tabbable</div>
          <div id="programmatic" tabindex="-1">Programmatic</div>
          <button id="hidden" type="button" hidden>Hidden</button>
          <div style="display: none"><button id="not-displayed" type="button">x</button></div>
          <button id="invisible" type="button" style="visibility: hidden">x</button>
          <div inert><button id="inert" type="button">x</button></div>
          <fieldset disabled><button id="in-fieldset" type="button">x</button></fieldset>
          <details>
            <summary id="summary">More</summary>
            <button id="in-closed-details" type="button">x</button>
          </details>
          <details open>
            <summary id="open-summary">Open</summary>
            <button id="in-open-details" type="button">y</button>
          </details>
        </div>
      </template>,
    )
    const container = byId('container')

    assert.deepEqual(ids(focusable.findAll({ container })), [
      'button',
      'input',
      'link',
      'tabbable-div',
      'summary',
      'open-summary',
      'in-open-details',
    ])
    assert.deepEqual(
      ids(focusable.findAll({ container, includeProgrammaticallyFocusable: true })),
      [
        'button',
        'input',
        'link',
        'tabbable-div',
        'programmatic',
        'summary',
        'open-summary',
        'in-open-details',
      ],
      'with includeProgrammaticallyFocusable, tabindex="-1" counts too',
    )
    assert.deepEqual(
      ids(focusable.findAll({ container, accept: element => element.tagName === 'BUTTON' })),
      ['button', 'in-open-details'],
      '`accept` filters the results',
    )

    assert.true(focusable.isFocusable(byId('button')))
    assert.true(focusable.isFocusable(byId('programmatic')), 'programmatic focus counts by default')
    assert.false(
      focusable.isFocusable(byId('programmatic'), { includeProgrammaticallyFocusable: false }),
    )
    for (const id of ['disabled', 'hidden', 'not-displayed', 'invisible', 'inert', 'in-fieldset']) {
      assert.false(focusable.isFocusable(byId(id)), `${id} can't take focus`)
    }
    assert.false(focusable.isFocusable(byId('in-closed-details')))
    assert.false(focusable.isFocusable(document.createElement('button')), 'not in the page')
    await a11yAudit()
  })

  test('focusable finds the first, the last, and the ones before and after an element', async function (assert) {
    await render(
      <template>
        <div id="container">
          <button id="a" type="button">A</button>
          <div id="group">
            <button id="b" type="button">B</button>
            <span id="text">Text</span>
            <button id="c" type="button">C</button>
          </div>
          <button id="d" type="button">D</button>
        </div>
      </template>,
    )
    const container = byId('container')
    assert.strictEqual(focusable.findFirst({ container })?.id, 'a')
    assert.strictEqual(focusable.findLast({ container })?.id, 'd')
    assert.strictEqual(focusable.findNext({ container, currentElement: byId('b') })?.id, 'c')
    assert.strictEqual(
      focusable.findNext({ container, currentElement: byId('text') })?.id,
      'c',
      'from an element that takes no focus',
    )
    assert.strictEqual(focusable.findPrev({ container, currentElement: byId('text') })?.id, 'b')
    assert.strictEqual(
      focusable.findNext({ container, currentElement: byId('group') })?.id,
      'b',
      'from a container, its own first child comes next',
    )
    assert.strictEqual(focusable.findNext({ container, currentElement: byId('d') }), undefined)
    assert.strictEqual(focusable.findPrev({ container, currentElement: byId('a') }), undefined)
    assert.strictEqual(
      focusable.findFirst({ container: byId('text') }),
      undefined,
      'nothing to find',
    )
    await a11yAudit()
  })

  test('focusFirst focuses the first candidate that takes focus, and stops at the focused one', async function (assert) {
    await render(
      <template>
        <button id="a" type="button" disabled>A</button>
        <button id="b" type="button">B</button>
        <button id="c" type="button">C</button>
        <input id="name" aria-label="Name" value="Ada" />
      </template>,
    )
    assert.true(focusFirst([null, byId('a'), byId('b'), byId('c')]))
    assert.dom('#b').isFocused('the disabled one is passed over')

    assert.false(focusFirst([byId('b'), byId('c')]), 'it stops at the element already focused')
    assert.dom('#b').isFocused()

    assert.true(focusElement(byId('name'), { select: true }))
    // Not `input`: a local of that name would be what <input> means in the template above.
    const field = byId('name') as HTMLInputElement
    assert.strictEqual(field.selectionStart, 0)
    assert.strictEqual(field.selectionEnd, 3, 'select: true selects the text')
    assert.false(focusElement(null))
    await a11yAudit()
  })

  test('restoreFocus moves focus within when the focused element is removed', async function (assert) {
    class State {
      @tracked items = ['Apple', 'Banana', 'Cherry']
      remove = (item: string) => (this.items = this.items.filter(other => other !== item))
    }
    const state = new State()

    await render(
      <template>
        <ul {{restoreFocus}}>
          {{#each state.items as |item|}}
            <li>
              <button id={{item}} type="button" {{on "click" (fn state.remove item)}}>
                Remove
                {{item}}
              </button>
            </li>
          {{/each}}
        </ul>
      </template>,
    )

    await focus('#Cherry')
    await focus('#Banana')
    await click('#Banana')
    assert.dom('#Banana').doesNotExist()
    assert.dom('#Cherry').isFocused('to the element focused before it, which is still there')

    await click('#Cherry')
    assert.dom('#Apple').isFocused('with no history left, to the first focusable element')

    state.items = [...state.items, 'Damson']
    await settled()
    assert.dom('#Apple').isFocused('adding elements moves nothing')
    await a11yAudit()
  })

  test('restoreFocus leaves focus alone when the user moved it away', async function (assert) {
    class State {
      @tracked items = ['Apple', 'Banana']
    }
    const state = new State()
    await render(
      <template>
        <ul {{restoreFocus}}>
          {{#each state.items as |item|}}
            <li><button id={{item}} type="button">{{item}}</button></li>
          {{/each}}
        </ul>
        <button id="outside" type="button">Outside</button>
      </template>,
    )

    await focus('#Banana')
    await blur('#Banana')
    state.items = ['Apple']
    await settled()
    assert.strictEqual(document.activeElement, document.body, 'blurred focus stays blurred')

    await focus('#Apple')
    await focus('#outside')
    state.items = []
    await settled()
    assert.dom('#outside').isFocused('focus outside stays outside')
    await a11yAudit()
  })

  test('restoreFocus prefers `preferred`, and onRestore can take over', async function (assert) {
    class State {
      @tracked items = ['Apple', 'Banana', 'Cherry']
      @tracked preferred: HTMLElement | null = null
      handled: string | undefined
      allow = true
      onRestore = (next: HTMLElement) => {
        this.handled = next.id
        return this.allow
      }
    }
    const state = new State()
    await render(
      <template>
        <ul {{restoreFocus preferred=state.preferred onRestore=state.onRestore}}>
          {{#each state.items as |item|}}
            <li><button id={{item}} type="button">{{item}}</button></li>
          {{/each}}
        </ul>
      </template>,
    )
    state.preferred = byId('Cherry')
    await settled()

    await focus('#Apple')
    await focus('#Banana')
    state.items = ['Apple', 'Cherry']
    await settled()
    assert.strictEqual(state.handled, 'Cherry')
    assert.dom('#Cherry').isFocused('the preferred element comes before the history')

    state.allow = false
    await focus('#Apple')
    state.items = ['Cherry']
    await settled()
    assert.strictEqual(state.handled, 'Cherry', 'onRestore hears where focus would go')
    assert.strictEqual(document.activeElement, document.body, 'and returning false keeps it there')
    await a11yAudit()
  })

  test('restoreFocus returns focus outside when its own element is removed', async function (assert) {
    class State {
      @tracked open = false
      toggle = () => (this.open = !this.open)
      close = () => (this.open = false)
    }
    const state = new State()
    await render(
      <template>
        <button id="trigger" type="button" {{on "click" state.toggle}}>Menu</button>
        {{#if state.open}}
          <div role="menu" {{restoreFocus}}>
            <button id="item" role="menuitem" type="button" {{on "click" state.close}}>
              Close
            </button>
          </div>
        {{/if}}
      </template>,
    )

    await click('#trigger')
    await focus('#item')
    await click('#item')
    assert.dom('#item').doesNotExist()
    assert.dom('#trigger').isFocused('back to what was focused before it')

    await click('#trigger')
    assert.dom('#trigger').isFocused()
    await click('#trigger')
    assert.dom('#trigger').isFocused('closing it while focus was outside moves nothing')
    await a11yAudit()
  })
})
