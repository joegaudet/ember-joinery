import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, find, focus, render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  FocusScope,
  addFocusGuards,
  createFocusScope,
  focusScope,
} from '@ember-joinery/primitives/focus-scope'
import { tab } from '@ember-joinery/test-support'

class Toggle {
  @tracked open = false
  @tracked items = ['one', 'two']
  show = () => (this.open = true)
  hide = () => (this.open = false)
}

/** The focus guards in the page: at the ends of <body>, outside the test's root. */
function guards(): number {
  return document.querySelectorAll('[data-jn-focus-guard]').length
}

module('Integration | primitives | focus-scope', function (hooks) {
  setupRenderingTest(hooks)

  test('focus moves in when the scope starts, to the first tabbable element that is not a link', async function (assert) {
    const state = new Toggle()
    await render(
      <template>
        <button id="open" type="button" {{on "click" state.show}}>Open</button>
        {{#if state.open}}
          <FocusScope id="scope" role="group" aria-label="Edit">
            <a href="#help">Help</a>
            <input id="name" aria-label="Name" value="Ada" />
            <button id="close" type="button" {{on "click" state.hide}}>Close</button>
          </FocusScope>
        {{/if}}
      </template>,
    )
    await click('#open')
    assert.dom('#scope').hasAttribute('tabindex', '-1').hasAttribute('data-slot', 'focus-scope')
    assert.dom('#name').isFocused('links are passed over')
    const name = find('#name') as HTMLInputElement
    assert.strictEqual(
      name.selectionEnd! - name.selectionStart!,
      3,
      "and an input's text is selected",
    )

    await click('#close')
    assert.dom('#scope').doesNotExist()
    assert.dom('#open').isFocused('focus returns to where it was when the scope started')
    await a11yAudit()
  })

  test('with nothing to focus inside, the scope itself takes focus', async function (assert) {
    const state = new Toggle()
    await render(
      <template>
        <button id="open" type="button" {{on "click" state.show}}>Open</button>
        {{#if state.open}}
          <FocusScope id="scope" role="note" aria-label="Note">Nothing to press.</FocusScope>
        {{/if}}
      </template>,
    )
    await click('#open')
    assert.dom('#scope').isFocused()
    await a11yAudit()
  })

  test('onMountAutoFocus and onUnmountAutoFocus can move focus themselves', async function (assert) {
    const state = new Toggle()
    const events: string[] = []
    const keepFocus = (event: Event) => {
      events.push(event.type)
      event.preventDefault()
    }
    const toOther = (event: Event) => {
      events.push(event.type)
      event.preventDefault()
      ;(find('#other') as HTMLElement).focus()
    }
    await render(
      <template>
        <button id="open" type="button" {{on "click" state.show}}>Open</button>
        <button id="other" type="button">Other</button>
        {{#if state.open}}
          <FocusScope
            @onMountAutoFocus={{keepFocus}}
            @onUnmountAutoFocus={{toOther}}
            role="group"
            aria-label="Edit"
          >
            <button id="close" type="button" {{on "click" state.hide}}>Close</button>
          </FocusScope>
        {{/if}}
      </template>,
    )
    await click('#open')
    assert.dom('#open').isFocused('the mount focus was prevented')
    await click('#close')
    assert.dom('#other').isFocused('the unmount focus went where the handler sent it')
    assert.deepEqual(events, ['focusScope.autoFocusOnMount', 'focusScope.autoFocusOnUnmount'])
    await a11yAudit()
  })

  test('@loop wraps Tab and Shift+Tab round the edges', async function (assert) {
    await render(
      <template>
        <button id="before" type="button">Before</button>
        <FocusScope @loop={{true}} role="group" aria-label="Edit">
          <button id="first" type="button">First</button>
          <button id="middle" type="button" disabled>Disabled</button>
          <button id="last" type="button">Last</button>
        </FocusScope>
        <button id="after" type="button">After</button>
      </template>,
    )
    assert.dom('#first').isFocused()
    await tab()
    assert.dom('#last').isFocused('the disabled button is passed over')
    await tab()
    assert.dom('#first').isFocused('Tab from the last goes to the first')
    await tab({ shift: true })
    assert.dom('#last').isFocused('Shift+Tab from the first goes to the last')

    await focus('#after')
    assert.dom('#after').isFocused('not trapped: focus can still leave')
    await a11yAudit()
  })

  test('@trapped keeps focus in: Tab stops at the edges, and focus that leaves comes back', async function (assert) {
    await render(
      <template>
        <button id="before" type="button">Before</button>
        <FocusScope @trapped={{true}} role="group" aria-label="Edit">
          <button id="first" type="button">First</button>
          <button id="last" type="button">Last</button>
        </FocusScope>
        <button id="after" type="button">After</button>
      </template>,
    )
    assert.dom('#first').isFocused()
    await tab()
    assert.dom('#last').isFocused()
    await tab()
    assert.dom('#last').isFocused('without @loop, Tab stops at the last')
    await focus('#first')
    await tab({ shift: true })
    assert.dom('#first').isFocused('and Shift+Tab at the first')

    await focus('#last')
    await focus('#after')
    assert.dom('#last').isFocused('focus moved outside comes back to the last focused inside')
    await click('#before')
    assert.dom('#last').isFocused('a click outside too')
    await a11yAudit()
  })

  test('without @trapped or @loop, Tab leaves the scope as usual', async function (assert) {
    await render(
      <template>
        <FocusScope role="group" aria-label="Edit">
          <button id="only" type="button">Only</button>
        </FocusScope>
        <button id="after" type="button">After</button>
      </template>,
    )
    assert.dom('#only').isFocused()
    await tab()
    assert.dom('#after').isFocused()
    await a11yAudit()
  })

  test('@trapped brings focus back to the scope when the focused element is removed', async function (assert) {
    const state = new Toggle()
    await render(
      <template>
        <FocusScope id="scope" @trapped={{true}} role="group" aria-label="List">
          {{#each state.items as |item|}}
            <button id={{item}} type="button">{{item}}</button>
          {{/each}}
        </FocusScope>
      </template>,
    )
    await focus('#two')
    state.items = ['one']
    await settled()
    assert.dom('#scope').isFocused()
    await a11yAudit()
  })

  test('a trapped scope puts focus guards at the ends of <body> while it traps', async function (assert) {
    const state = new Toggle()
    await render(
      <template>
        <button id="open" type="button" {{on "click" state.show}}>Open</button>
        {{#if state.open}}
          <FocusScope @trapped={{true}} role="group" aria-label="Edit">
            <button id="close" type="button" {{on "click" state.hide}}>Close</button>
          </FocusScope>
        {{/if}}
      </template>,
    )
    assert.strictEqual(guards(), 0)
    await click('#open')
    const all = document.querySelectorAll('[data-jn-focus-guard]')
    assert.strictEqual(guards(), 2)
    assert.strictEqual(document.body.firstElementChild, all[0], 'one at the start of <body>')
    assert.strictEqual(document.body.lastElementChild, all[1], 'one at the end')
    assert.strictEqual((all[0] as HTMLElement).tabIndex, 0)

    const release = addFocusGuards()
    await click('#close')
    assert.strictEqual(guards(), 2, 'shared: they stay while anyone holds them')
    release()
    release()
    assert.strictEqual(guards(), 0, 'and go with the last')
    await a11yAudit()
  })

  test('a newer scope pauses the one before it, which resumes when it ends', async function (assert) {
    const state = new Toggle()
    await render(
      <template>
        <FocusScope @trapped={{true}} role="group" aria-label="Outer">
          <button id="outer" type="button" {{on "click" state.show}}>Open inner</button>
        </FocusScope>
        {{#if state.open}}
          <FocusScope @trapped={{true}} role="group" aria-label="Inner">
            <button id="inner" type="button" {{on "click" state.hide}}>Close inner</button>
            <button id="inner-last" type="button">Last</button>
          </FocusScope>
        {{/if}}
      </template>,
    )
    assert.dom('#outer').isFocused()
    await click('#outer')
    assert.dom('#inner').isFocused('the outer trap lets focus go to the newer scope')
    await tab()
    assert.dom('#inner-last').isFocused()
    await tab()
    assert.dom('#inner-last').isFocused('the inner scope traps')

    await click('#inner')
    assert.dom('#outer').isFocused('focus returns to the outer scope')
    await focus('#outer')
    await tab()
    assert.dom('#outer').isFocused('which traps again')
    await a11yAudit()
  })

  test('{{focusScope}} makes any element a scope, and keeps its own tabindex', async function (assert) {
    class State {
      @tracked trapped = false
    }
    const state = new State()
    await render(
      <template>
        <section id="own" tabindex="0" aria-label="Own" {{focusScope}}>Text</section>
      </template>,
    )
    assert.dom('#own').hasAttribute('tabindex', '0', "an element's own tabindex stays")

    await render(
      <template>
        <div id="plain" role="group" aria-label="Plain" {{focusScope trapped=state.trapped}}>
          <button id="inside" type="button">Inside</button>
        </div>
        <button id="outside" type="button">Outside</button>
      </template>,
    )
    assert.dom('#plain').hasAttribute('tabindex', '-1', 'and one without gets tabindex="-1"')

    await focus('#inside')
    await focus('#outside')
    assert.dom('#outside').isFocused('not trapped yet')

    state.trapped = true
    await settled()
    await focus('#inside')
    await focus('#outside')
    assert.dom('#inside').isFocused('trapped once the argument changes')
    await a11yAudit()
  })

  test('createFocusScope starts a scope on an element, and destroy() returns focus', async function (assert) {
    await render(
      <template>
        <button id="start" type="button">Start</button>
        <div id="panel" tabindex="-1" role="group" aria-label="Panel">
          <button id="panel-button" type="button">Inside</button>
        </div>
      </template>,
    )
    await focus('#start')
    const scope = createFocusScope(find('#panel') as HTMLElement, { trapped: true })
    await settled()
    assert.dom('#panel-button').isFocused()
    assert.false(scope.paused)

    scope.update({ trapped: false })
    await focus('#start')
    assert.dom('#start').isFocused('update() stops the trap')

    await focus('#panel-button')
    scope.destroy()
    await settled()
    assert.dom('#start').isFocused()
    await a11yAudit()
  })
})
