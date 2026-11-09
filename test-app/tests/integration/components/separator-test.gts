import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { rendering } from 'test-app/tests/helpers/rendering'
import { find, getRootElement, render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  Separator,
  asSeparator,
  separatorAttributes,
  separatorClasses,
  type SeparatorOrientation,
} from '@ember-joinery/ember'
import { SeparatorHarness } from '@ember-joinery/test-support'

/** What a CSS colour (`var(--border)`) computes to here, to compare with a rendered one. */
function color(value: string): string {
  const probe = document.createElement('div')
  probe.style.backgroundColor = value
  getRootElement().append(probe)
  const computed = getComputedStyle(probe).backgroundColor
  probe.remove()
  return computed
}

module('Integration | components | separator', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a decorative div with upstream classes and data attributes', async function (assert) {
    await render(<template><Separator /></template>)
    const separator = new SeparatorHarness()
    assert
      .dom(separator.element)
      .hasTagName('div')
      .hasClass('jn-separator')
      .hasAttribute('data-slot', 'separator')
      .hasAttribute('data-orientation', 'horizontal')
      .hasAttribute('role', 'none', "Radix's decorative separator")
      .hasAttribute('aria-hidden', 'true')
      .hasAttribute('data-test-jn', 'separator')
    assert.true(separator.isDecorative, 'decorative by default, as upstream')
    assert.strictEqual(separator.orientation, 'horizontal')
    await a11yAudit()
  })

  test('its style sheet draws a 1px line across, or down its row', async function (assert) {
    await render(
      <template>
        <div style="width: 300px">
          <Separator @name="horizontal" />
        </div>
        <div style="display: flex; height: 20px; align-items: center; gap: 16px">
          <div>Blog</div>
          <Separator @name="vertical" @orientation="vertical" />
          <div>Docs</div>
        </div>
      </template>,
    )
    const horizontal = new SeparatorHarness('horizontal').element
    const style = getComputedStyle(horizontal)
    assert.strictEqual(style.height, '1px', 'data-horizontal:h-px')
    assert.strictEqual(style.width, '300px', 'data-horizontal:w-full')
    assert.strictEqual(style.backgroundColor, color('var(--border)'), 'bg-border')
    assert.strictEqual(style.flexShrink, '0')

    const vertical = new SeparatorHarness('vertical')
    assert.strictEqual(vertical.orientation, 'vertical')
    const box = getComputedStyle(vertical.element)
    assert.strictEqual(box.width, '1px', 'data-vertical:w-px')
    assert.strictEqual(box.height, '20px', 'data-vertical:self-stretch: the height of its row')
    await a11yAudit()
  })

  test('@decorative={{false}} makes it a separator assistive technology reads', async function (assert) {
    await render(
      <template>
        <Separator @name="semantic" @decorative={{false}} />
        <div style="display: flex; height: 20px">
          <Separator @name="vertical" @decorative={{false}} @orientation="vertical" />
        </div>
      </template>,
    )
    const semantic = new SeparatorHarness('semantic')
    assert
      .dom(semantic.element)
      .hasAttribute('role', 'separator')
      .doesNotHaveAttribute('aria-hidden')
      .doesNotHaveAttribute('aria-orientation')
    assert.false(semantic.isDecorative)
    assert.strictEqual(semantic.role, 'separator')
    const vertical = new SeparatorHarness('vertical')
    assert.dom(vertical.element).hasAttribute('aria-orientation', 'vertical')
    assert.strictEqual(vertical.orientation, 'vertical')
    await a11yAudit()
  })

  test('it takes attributes, @as and a class of its own', async function (assert) {
    await render(
      <template>
        <ul style="width: 200px">
          <li>One</li>
          <Separator @as="li" @name="item" class="mine" />
          <li>Two</li>
        </ul>
        <Separator @as="hr" @name="hr" @decorative={{false}} />
      </template>,
    )
    const item = new SeparatorHarness('item')
    assert.dom(item.element).hasTagName('li').hasClass('mine').hasClass('jn-separator')
    assert.strictEqual(getComputedStyle(item.element).height, '1px')
    const hr = new SeparatorHarness('hr')
    assert.dom(hr.element).hasTagName('hr').doesNotHaveAttribute('role', "an <hr>'s own")
    assert.strictEqual(hr.role, 'separator')
    assert.strictEqual(getComputedStyle(hr.element).height, '1px', 'no border of its own')
    assert.strictEqual(getComputedStyle(hr.element).borderTopWidth, '0px')
    await a11yAudit()
  })

  test('keyboard: a separator takes no focus (it is not the splitter of Resizable)', async function (assert) {
    await render(<template><Separator @decorative={{false}} /></template>)
    const separator = new SeparatorHarness().element
    assert.strictEqual(separator.tabIndex, -1)
    separator.focus()
    assert.notStrictEqual(document.activeElement, separator)
    await a11yAudit()
  })

  test('the asSeparator modifier makes any element a separator, and follows its arguments', async function (assert) {
    class State {
      @tracked orientation: SeparatorOrientation = 'horizontal'
    }
    const state = new State()
    await render(
      <template>
        <Separator @name="x" data-case="component" />
        <div data-case="modifier" {{asSeparator name="x"}}></div>
        <Separator @name="y" @decorative={{false}} @orientation="vertical" data-case="component" />
        <div
          data-case="modifier"
          {{asSeparator name="y" decorative=false orientation="vertical"}}
        ></div>
        <div style="display: flex; height: 20px">
          <span {{asSeparator name="live" orientation=state.orientation}}></span>
        </div>
      </template>,
    )
    const components = [...document.querySelectorAll('[data-case="component"]')]
    const modifiers = [...document.querySelectorAll('[data-case="modifier"]')]
    components.forEach((component, index) => {
      assert.deepEqual(rendering(component), rendering(modifiers[index]!), `${index}: the same`)
    })
    const first = find('[data-case="component"]')!
    assert.deepEqual(rendering(first).classes, separatorClasses().split(' ').sort())
    for (const [name, value] of Object.entries(separatorAttributes({ name: 'x' }))) {
      assert.strictEqual(first.getAttribute(name), value ?? null, name)
    }

    const live = new SeparatorHarness('live')
    assert.strictEqual(getComputedStyle(live.element).height, '1px')
    state.orientation = 'vertical'
    await settled()
    assert.strictEqual(live.orientation, 'vertical', 'it follows')
    assert.strictEqual(getComputedStyle(live.element).width, '1px')
    assert.strictEqual(getComputedStyle(live.element).height, '20px')
    await a11yAudit()
  })

  test('RTL: a vertical separator stays between its neighbours, which swap sides', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div style="display: flex; height: 20px; gap: 16px">
            <div id="first">مدونة</div>
            <Separator @name="rtl" @orientation="vertical" />
            <div id="second">المستندات</div>
          </div>
          <div style="width: 300px"><Separator @name="across" /></div>
        </DirectionProvider>
      </template>,
    )
    const separator = new SeparatorHarness('rtl').element.getBoundingClientRect()
    const first = find('#first')!.getBoundingClientRect()
    const second = find('#second')!.getBoundingClientRect()
    assert.ok(first.left > separator.right, 'the first item is on the right')
    assert.ok(second.right < separator.left, 'the second on the left')
    assert.strictEqual(getComputedStyle(new SeparatorHarness('across').element).width, '300px')
    await a11yAudit()
  })
})
