import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, find, findAll, render, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { LinkTo } from '@ember/routing'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { part } from '@ember-joinery/primitives/part'
import {
  FxPrimitiveDisclosure,
  FxPrimitiveDisclosureHarness,
} from 'test-app/tests/fixtures/primitives/disclosure'

module('Integration | primitives | part', function (hooks) {
  setupRenderingTest(hooks)

  test("a part's own component renders the part's attributes", async function (assert) {
    await render(
      <template>
        <FxPrimitiveDisclosure as |d|>
          <d.Trigger class="mine">Details</d.Trigger>
          <d.Content>The details.</d.Content>
        </FxPrimitiveDisclosure>
      </template>,
    )
    const disclosure = new FxPrimitiveDisclosureHarness()
    assert.dom(disclosure.trigger).hasTagName('button').hasClass('mine')
    assert.dom(disclosure.trigger).hasAttribute('data-state', 'closed')
    assert.dom(disclosure.trigger).doesNotHaveAttribute('aria-controls')
    assert.false(disclosure.isOpen)

    await disclosure.toggle()
    assert.true(disclosure.isOpen)
    assert.dom(disclosure.trigger).hasAttribute('data-state', 'open')
    assert.dom(disclosure.trigger).hasAttribute('aria-controls', disclosure.content!.id)
    assert.dom(disclosure.content).hasText('The details.')

    await disclosure.toggle()
    assert.dom(disclosure.trigger).doesNotHaveAttribute('aria-controls', 'removed again')
    assert.strictEqual(disclosure.content, null)
    await a11yAudit()
  })

  test('@as renders the part as another element', async function (assert) {
    await render(
      <template>
        <FxPrimitiveDisclosure as |d|>
          <d.Trigger @as="span" role="button" tabindex="0">Details</d.Trigger>
          <d.Content>The details.</d.Content>
        </FxPrimitiveDisclosure>
      </template>,
    )
    const disclosure = new FxPrimitiveDisclosureHarness()
    assert.dom(disclosure.trigger).hasTagName('span')
    await disclosure.toggle()
    assert.true(disclosure.isOpen)
    await a11yAudit()
  })

  test('the yielded modifier makes any element the part', async function (assert) {
    await render(
      <template>
        <FxPrimitiveDisclosure as |d|>
          <a href="#details" {{d.trigger}}>Details</a>
          <d.Content>The details.</d.Content>
          {{#if d.isOpen}}<p>Open</p>{{/if}}
        </FxPrimitiveDisclosure>
      </template>,
    )
    const disclosure = new FxPrimitiveDisclosureHarness()
    assert.dom(disclosure.trigger).hasTagName('a').hasAttribute('href', '#details')
    assert.dom(disclosure.trigger).hasAttribute('data-slot', 'disclosure-trigger')

    await disclosure.toggle()
    assert.true(disclosure.isOpen)
    assert.dom('p').hasText('Open')
    await a11yAudit()
  })

  test('the yielded modifier works on a component, such as LinkTo', async function (assert) {
    ;(this.owner as unknown as { setupRouter(): void }).setupRouter()
    await render(
      <template>
        <FxPrimitiveDisclosure as |d|>
          <LinkTo @route="index" {{d.trigger}}>Details</LinkTo>
        </FxPrimitiveDisclosure>
      </template>,
    )
    const disclosure = new FxPrimitiveDisclosureHarness()
    assert.dom(disclosure.trigger).hasTagName('a').hasAttribute('href', '/')
    assert.dom(disclosure.trigger).hasAttribute('aria-expanded', 'false')
    assert.dom(disclosure.trigger).hasAttribute('data-test-jn-part', 'trigger')
    await a11yAudit()
  })

  test('attributes it stops setting go back to the element’s own', async function (assert) {
    class State {
      @tracked titled = false
      @tracked classes = 'one two'
    }
    const state = new State()
    const labelled = part(() => ({
      attributes: { title: state.titled ? 'From the part' : undefined, 'data-on': state.titled },
      class: state.classes,
    }))

    await render(
      <template>
        <span title="Own" class="own two" {{labelled}}>Text</span>
      </template>,
    )
    assert.dom('span').hasAttribute('title', 'Own').doesNotHaveAttribute('data-on')
    assert.dom('span').hasClass('one').hasClass('two').hasClass('own')

    state.titled = true
    state.classes = 'three'
    await settled()
    assert.dom('span').hasAttribute('title', 'From the part').hasAttribute('data-on', '')
    assert.dom('span').hasClass('three').doesNotHaveClass('one', 'a class it dropped is removed')
    assert.dom('span').hasClass('two', 'a class the element had stays')
    assert.dom('span').hasClass('own')

    state.titled = false
    await settled()
    assert.dom('span').hasAttribute('title', 'Own', 'the original comes back')
    assert.dom('span').doesNotHaveAttribute('data-on')
    await a11yAudit()
  })

  test("the part's classes and attributes stay when the element's own re-render", async function (assert) {
    class State {
      @tracked classes = 'one'
      @tracked title = 'Own'
      @tracked expanded = false
    }
    const state = new State()
    const trigger = part(() => ({
      attributes: { title: 'From the part', 'aria-expanded': String(state.expanded) },
      class: 'jn-trigger',
    }))

    await render(
      <template>
        <button type="button" class={{state.classes}} title={{state.title}} {{trigger}}>
          Go
        </button>
      </template>,
    )
    assert.dom('button').hasClass('one').hasClass('jn-trigger')
    assert.dom('button').hasAttribute('title', 'From the part')

    // As LinkTo's `active` class does on a route change: only the element's own change.
    state.classes = 'two'
    state.title = 'Own, changed'
    await settled()
    assert.dom('button').hasClass('two').doesNotHaveClass('one')
    assert.dom('button').hasClass('jn-trigger', "the part's class is put back")
    assert.dom('button').hasAttribute('title', 'From the part', "the part's attribute still wins")

    // Both at once: the element's class and the part's state change in one render.
    state.classes = 'three'
    state.expanded = true
    await settled()
    assert.dom('button').hasClass('three').hasClass('jn-trigger').hasAria('expanded', 'true')
    await a11yAudit()
  })

  test('an attribute it stops setting goes back to the element’s current value', async function (assert) {
    class State {
      @tracked titled = true
      @tracked title = 'First'
    }
    const state = new State()
    const labelled = part(() => ({
      attributes: { title: state.titled ? 'From the part' : undefined },
    }))

    await render(
      <template>
        <span title={{state.title}} {{labelled}}>Text</span>
      </template>,
    )
    state.title = 'Second'
    await settled()
    assert.dom('span').hasAttribute('title', 'From the part')

    state.titled = false
    await settled()
    assert.dom('span').hasAttribute('title', 'Second', "the element's value now, not its first")

    state.titled = true
    await settled()
    state.title = 'Third'
    await settled()
    state.titled = false
    await settled()
    assert.dom('span').hasAttribute('title', 'Third')
    await a11yAudit()
  })

  test('two parts on one element: the last to set an attribute wins', async function (assert) {
    class State {
      @tracked open = false
    }
    const state = new State()
    const dialogTrigger = part(() => ({
      attributes: { 'data-state': state.open ? 'open' : 'closed', 'aria-haspopup': 'dialog' },
      class: 'jn-dialog-trigger',
    }))
    const tooltipTrigger = part(() => ({
      attributes: { 'data-state': 'delayed-open' },
      class: 'jn-tooltip-trigger',
    }))

    await render(
      <template>
        <button type="button" {{dialogTrigger}} {{tooltipTrigger}}>Open</button>
      </template>,
    )
    assert.dom('button').hasAttribute('data-state', 'delayed-open')
    assert.dom('button').hasClass('jn-dialog-trigger').hasClass('jn-tooltip-trigger')

    state.open = true
    await settled()
    assert.dom('button').hasAttribute('data-state', 'open', 'the dialog trigger set it last')
    assert.dom('button').hasAttribute('aria-haspopup', 'dialog')
    await a11yAudit()
  })

  test("the caller's listener comes first, and can stop the part's", async function (assert) {
    const calls: string[] = []
    const counted = part(() => ({ on: { click: () => calls.push('part') } }))
    const mine = (event: MouseEvent) => {
      calls.push('mine')
      if ((event.currentTarget as HTMLElement).id === 'stop') event.preventDefault()
    }

    await render(
      <template>
        <button id="go" type="button" {{on "click" mine}} {{counted}}>Go</button>
        <button id="stop" type="button" {{on "click" mine}} {{counted}}>Stop</button>
      </template>,
    )
    await click('#go')
    assert.deepEqual(calls, ['mine', 'part'])
    await click('#stop')
    assert.deepEqual(calls, ['mine', 'part', 'mine'], 'preventDefault() skipped the part')
    await a11yAudit()
  })

  test('a part can take arguments, and hear when its element comes and goes', async function (assert) {
    class State {
      @tracked items = ['apple', 'pear']
    }
    const state = new State()
    const seen: string[] = []
    const item = part((named: { value: string }) => ({
      attributes: { 'data-test-jn-value': named.value, 'data-test-jn-part': 'item' },
      element: element => {
        seen.push(`+${element.textContent}`)
        return () => seen.push(`-${element.textContent}`)
      },
    }))

    await render(
      <template>
        <ul>
          {{#each state.items as |name|}}
            <li {{item value=name}}>{{name}}</li>
          {{/each}}
        </ul>
      </template>,
    )
    assert.deepEqual(
      findAll('li').map(li => li.getAttribute('data-test-jn-value')),
      ['apple', 'pear'],
    )

    state.items = ['pear']
    await settled()
    assert.deepEqual(seen, ['+apple', '+pear', '-apple'], 'installed once each, cleaned up once')
    assert.dom(find('li')).hasAttribute('data-test-jn-value', 'pear')
    await a11yAudit()
  })
})
