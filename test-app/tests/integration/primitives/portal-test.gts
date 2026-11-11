import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  PORTALS,
  Portal,
  PortalTarget,
  PortalTargets,
  findNearestTarget,
  wormhole,
} from '@ember-joinery/primitives/portal'

class State {
  @tracked shown = true
  @tracked count = 0
  increment = () => (this.count += 1)
}

const target = (name: string) => document.querySelector(`[data-portal-name="${name}"]`)!

module('Integration | primitives | portal', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders into the nearest target by name', async function (assert) {
    await render(
      <template>
        <PortalTargets />
        <div id="origin">
          <Portal @to="popover"><p id="moved">Moved</p></Portal>
        </div>
      </template>,
    )
    assert.dom(target(PORTALS.popover).querySelector('#moved')).exists('in the popover target')
    assert.dom('#origin #moved').doesNotExist('not where the portal is')
    await a11yAudit()
  })

  test('it takes the full target names too, and a target of your own', async function (assert) {
    await render(
      <template>
        <PortalTargets />
        <PortalTarget @name="sidebar" id="sidebar" />
        <Portal @to={{PORTALS.tooltip}}><p id="tip">Tip</p></Portal>
        <Portal @to="sidebar"><p id="side">Side</p></Portal>
      </template>,
    )
    assert.dom(target(PORTALS.tooltip).querySelector('#tip')).exists()
    assert.dom('#sidebar #side').exists('in the registered target')
    await a11yAudit()
  })

  test('a target of your own can come after the portal, or later still', async function (assert) {
    const state = new State()
    state.shown = false
    await render(
      <template>
        <Portal @to="tray"><p id="note">Note</p></Portal>
        <PortalTarget @name="tray" id="first-tray" />
        {{#if state.shown}}
          <section><PortalTarget @name="tray" id="second-tray" /></section>
        {{/if}}
      </template>,
    )
    assert.dom('#first-tray #note').exists('found once the render was over')

    state.shown = true
    await settled()
    assert.dom('#first-tray #note').exists('the nearest registered target still holds it')
    await a11yAudit()
  })

  test('the content stays the component’s own: its state and its actions', async function (assert) {
    const state = new State()
    await render(
      <template>
        <PortalTargets />
        {{#if state.shown}}
          <Portal @to="modal">
            <button id="count" type="button" {{on "click" state.increment}}>{{state.count}}</button>
          </Portal>
        {{/if}}
      </template>,
    )
    await click('#count')
    assert.dom('#count').hasText('1', 'its actions run and it re-renders in place')
    assert.dom(target(PORTALS.modal).querySelector('#count')).exists()

    state.shown = false
    await settled()
    assert.dom('#count').doesNotExist('it goes with its component')
    await a11yAudit()
  })

  test('@append adds to the target; without it the content replaces it', async function (assert) {
    const host = document.createElement('div')
    host.innerHTML = '<p id="existing">Existing</p>'
    document.getElementById('ember-testing')!.append(host)
    await render(
      <template>
        <Portal @to={{host}} @append={{true}}><p id="added">Added</p></Portal>
      </template>,
    )
    assert.dom(host.querySelector('#existing')).exists('kept')
    assert.dom(host.querySelector('#added')).exists('added after it')

    await render(
      <template>
        <Portal @to={{host}}><p id="replaced">Replaced</p></Portal>
      </template>,
    )
    assert.dom(host.querySelector('#existing')).doesNotExist('replaced')
    assert.dom(host.querySelector('#replaced')).exists()
    host.remove()
    await a11yAudit()
  })

  test('@wormhole takes an id or a selector, as ember-wormhole does', async function (assert) {
    await render(
      <template>
        <Portal @wormhole="later"><p id="arrived">Arrived</p></Portal>
        <div id="later"></div>
      </template>,
    )
    assert.dom('#later #arrived').exists('found once the render was over')
    assert.strictEqual(wormhole('#later'), document.getElementById('later'))
    await a11yAudit()
  })

  test('without a target, it renders at the end of <body>, as Radix’s does', async function (assert) {
    await render(
      <template>
        <Portal><p id="at-body">At the end of body</p></Portal>
      </template>,
    )
    assert.strictEqual(document.getElementById('at-body')!.parentElement, document.body)
    await a11yAudit()
  })

  test('findNearestTarget looks up from the origin', async function (assert) {
    await render(
      <template>
        <section id="outer">
          <div data-portal-name={{PORTALS.popover}} id="outer-target"></div>
          <section id="inner">
            <div data-portal-name={{PORTALS.popover}} id="inner-target"></div>
            <span id="origin"></span>
          </section>
        </section>
      </template>,
    )
    const origin = document.getElementById('origin')!
    assert.strictEqual(findNearestTarget(origin, 'popover')?.id, 'inner-target', 'the nearest')
    assert.strictEqual(findNearestTarget(origin, '#outer-target')?.id, 'outer-target', 'a selector')
    await a11yAudit()
  })
})
