import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { isInTopLayer as primitiveIsInTopLayer, topLayer } from '@ember-joinery/primitives/layer'
import { dismissableLayers } from '@ember-joinery/primitives/dismiss'
import { isInTopLayer, pressEscape } from '@ember-joinery/test-support'
import {
  FxLayeredPopover,
  FxLayeredPopoverHarness,
} from 'test-app/tests/fixtures/primitives/layered-popover'

class State {
  @tracked shown = true
}

/** Elements the browser centres in the viewport, as it does popovers, so they overlap. */
const Overlapping = <template>
  <style>
    .layer-test {
      width: 120px;
      height: 80px;
    }
  </style>
</template>

module('Integration | primitives | layer', function (hooks) {
  setupRenderingTest(hooks)

  test('it puts the element in the top layer, and takes it out again', async function (assert) {
    const state = new State()
    await render(
      <template>
        <div style="overflow: hidden; width: 0; height: 0">
          {{#if state.shown}}
            <div id="layer" popover="hint" {{topLayer}}>Above everything</div>
          {{/if}}
        </div>
      </template>,
    )
    const layer = document.getElementById('layer')!
    assert.true(isInTopLayer(layer), 'shown once the render is over')
    assert.true(primitiveIsInTopLayer(layer))
    assert.dom(layer).hasAttribute('popover', 'manual')
    assert.true(layer.getBoundingClientRect().width > 0, 'its container does not clip it')
    await a11yAudit()

    state.shown = false
    await settled()
    assert.false(isInTopLayer(layer))
  })

  test('a layer inside another goes above it, even when they open together', async function (assert) {
    await render(
      <template>
        <Overlapping />
        <div id="outer" class="layer-test" {{topLayer}}>
          Outer
          <div id="inner" class="layer-test" {{topLayer}}>Inner</div>
        </div>
      </template>,
    )
    const outer = document.getElementById('outer')!
    const inner = document.getElementById('inner')!
    assert.true(isInTopLayer(outer))
    assert.true(isInTopLayer(inner))
    const rect = inner.getBoundingClientRect()
    const top = document.elementFromPoint(rect.left + rect.width / 2, rect.top + rect.height / 2)
    assert.true(inner.contains(top), 'the inner layer is on top where they overlap')
    await a11yAudit()
  })

  test('the modifier puts the popover attribute back', async function (assert) {
    const state = new State()
    await render(
      <template>
        <div id="layer" popover="hint" {{(if state.shown (modifier topLayer popover="auto"))}}>
          Hi
        </div>
      </template>,
    )
    const layer = document.getElementById('layer')!
    assert.dom(layer).hasAttribute('popover', 'auto')
    assert.true(isInTopLayer(layer))
    await a11yAudit()

    state.shown = false
    await settled()
    assert.false(isInTopLayer(layer), 'out of the top layer')
    assert.dom(layer).hasAttribute('popover', 'hint', 'the element’s own value is back')
  })

  test('an auto popover tells its component when the browser hides it', async function (assert) {
    await render(
      <template>
        <FxLayeredPopover @name="first" @popover="auto" as |p|>
          <p.Trigger>First</p.Trigger>
          <p.Content>First content</p.Content>
        </FxLayeredPopover>
        <FxLayeredPopover @name="second" @popover="auto" as |p|>
          <p.Trigger>Second</p.Trigger>
          <p.Content>Second content</p.Content>
        </FxLayeredPopover>
      </template>,
    )
    const first = new FxLayeredPopoverHarness('first')
    const second = new FxLayeredPopoverHarness('second')
    await first.open()
    assert.true(first.isInTopLayer)
    assert.dom(first.content).hasAttribute('popover', 'auto')

    // Opening another auto popover hides the first, as the browser's light dismiss does.
    await second.open()
    await settled()
    assert.false(first.isOpen, 'the first closed with the browser')
    assert.true(second.isInTopLayer)

    second.content!.hidePopover()
    await settled()
    assert.false(second.isOpen, 'and when something else hides it')
    await a11yAudit()
  })

  test('Escape leaves an auto popover on top to the browser', async function (assert) {
    await render(
      <template>
        <FxLayeredPopover @name="manual" as |outer|>
          <outer.Trigger>Manual</outer.Trigger>
          <outer.Content>
            <FxLayeredPopover @name="auto" @popover="auto" as |inner|>
              <inner.Trigger>Auto</inner.Trigger>
              <inner.Content>Auto content</inner.Content>
            </FxLayeredPopover>
          </outer.Content>
        </FxLayeredPopover>
      </template>,
    )
    const manual = new FxLayeredPopoverHarness('manual')
    const auto = new FxLayeredPopoverHarness('auto')
    await manual.open()
    await auto.open()
    assert.true(auto.isInTopLayer, 'the nested auto popover keeps its parent open')
    assert.strictEqual(dismissableLayers().at(-1), auto.content, 'and is on top of the stack')

    let prevented: boolean | undefined
    const listen = (event: KeyboardEvent) => (prevented = event.defaultPrevented)
    document.addEventListener('keydown', listen)
    await pressEscape(auto.trigger)
    document.removeEventListener('keydown', listen)
    assert.true(manual.isOpen, 'the manual layer underneath stays')
    assert.false(prevented, 'the keydown goes on to the browser, whose close request it is')
    await a11yAudit()
  })
})
