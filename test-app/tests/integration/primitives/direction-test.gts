import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { find, render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  DirectionProvider,
  getDirection,
  isRTL,
  type Direction,
} from '@ember-joinery/primitives/direction'

module('Integration | primitives | direction', function (hooks) {
  setupRenderingTest(hooks)

  test('DirectionProvider sets the direction inside it, and adds no box', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl" class="app" as |dir|>
          <p>{{dir}}</p>
        </DirectionProvider>
      </template>,
    )
    const provider = find('[data-slot="direction-provider"]')!
    assert.dom(provider).hasAttribute('dir', 'rtl')
    assert.dom(provider).hasClass('app', 'it takes attributes')
    assert.strictEqual(getComputedStyle(provider).display, 'contents', 'no box of its own')
    assert.dom('p').hasText('rtl', 'it yields the direction')
    assert.strictEqual(getDirection(find('p')), 'rtl', 'content reads it from the document')
    assert.strictEqual(getComputedStyle(find('p')!).direction, 'rtl', 'and the layout follows it')
    await a11yAudit()
  })

  test('@direction wins over @dir, and the default is ltr', async function (assert) {
    class State {
      @tracked direction: Direction | undefined = 'rtl'
    }
    const state = new State()
    await render(
      <template>
        <DirectionProvider @dir="ltr" @direction={{state.direction}} as |dir|>
          <p>{{dir}}</p>
        </DirectionProvider>
        <DirectionProvider as |dir|><output>{{dir}}</output></DirectionProvider>
      </template>,
    )
    assert.dom('p').hasText('rtl', "shadcn's @direction wins")
    assert.dom('output').hasText('ltr', 'ltr without either')

    state.direction = undefined
    await settled()
    assert.dom('p').hasText('ltr', 'then @dir')
  })

  test('getDirection reads the nearest dir, and an explicit one wins', async function (assert) {
    await render(
      <template>
        <div dir="rtl">
          <span id="inherits">a</span>
          <DirectionProvider @dir="ltr"><span id="nested">b</span></DirectionProvider>
          <p id="auto" dir="auto">שלום עולם</p>
        </div>
        <span id="outside">c</span>
      </template>,
    )
    assert.strictEqual(getDirection(find('#inherits')), 'rtl', 'inherited from an ancestor')
    assert.strictEqual(getDirection(find('#nested')), 'ltr', 'the nearest provider wins')
    assert.strictEqual(getDirection(find('#auto')), 'rtl', 'dir="auto" resolves from the text')
    assert.strictEqual(getDirection(find('#outside')), 'ltr')
    assert.strictEqual(getDirection(find('#outside'), 'rtl'), 'rtl', "a component's @dir wins")
    assert.strictEqual(
      getDirection(find('#inherits'), 'sideways'),
      'rtl',
      'an invalid one is ignored',
    )
    assert.strictEqual(getDirection(), 'ltr', 'with no element, <html>')
    assert.true(isRTL(find('#inherits')))
    assert.false(isRTL(find('#nested')))
  })

  test('content in the top layer keeps the direction it was rendered in', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div id="layer" popover="manual">In the top layer</div>
        </DirectionProvider>
      </template>,
    )
    const layer = find('#layer') as HTMLElement
    layer.showPopover()
    assert.true(layer.matches(':popover-open'))
    assert.strictEqual(getDirection(layer), 'rtl')
    assert.strictEqual(getComputedStyle(layer).direction, 'rtl')
    layer.hidePopover()
  })
})
