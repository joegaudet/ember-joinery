import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  Separator,
  separatorAria,
  type SeparatorOrientation,
} from '@ember-joinery/primitives/separator'
import { SeparatorHarness } from '@ember-joinery/test-support'

module('Integration | primitives | separator', function (hooks) {
  setupRenderingTest(hooks)

  test('it is an <hr> by default, a separator already', async function (assert) {
    await render(
      <template>
        <p>Above</p>
        <Separator class="mine" />
        <p>Below</p>
      </template>,
    )
    const separator = new SeparatorHarness()
    assert
      .dom(separator.element)
      .hasTagName('hr')
      .hasClass('mine')
      .doesNotHaveAttribute('role', "an <hr>'s own role")
      .doesNotHaveAttribute('aria-orientation', "horizontal is the role's default")
      .doesNotHaveAttribute('aria-hidden')
      .hasAttribute('data-orientation', 'horizontal')
      .doesNotHaveAttribute('data-slot', 'no styles, so no slot')
    assert.strictEqual(separator.role, 'separator')
    assert.strictEqual(separator.orientation, 'horizontal')
    assert.false(separator.isDecorative)
    await a11yAudit()
  })

  test('with another tag it takes the separator role, and vertical is in its ARIA', async function (assert) {
    await render(
      <template>
        <div style="display: flex">
          <span>Blog</span>
          <Separator @as="div" @name="vertical" @orientation="vertical" />
          <span>Docs</span>
        </div>
        <Separator @as="div" @name="horizontal" />
      </template>,
    )
    const vertical = new SeparatorHarness('vertical')
    assert
      .dom(vertical.element)
      .hasTagName('div')
      .hasAttribute('role', 'separator')
      .hasAttribute('aria-orientation', 'vertical')
      .hasAttribute('data-orientation', 'vertical')
    assert.strictEqual(vertical.orientation, 'vertical')
    assert.strictEqual(vertical.role, 'separator')

    const horizontal = new SeparatorHarness('horizontal')
    assert
      .dom(horizontal.element)
      .hasAttribute('role', 'separator')
      .doesNotHaveAttribute('aria-orientation')
    assert.strictEqual(horizontal.orientation, 'horizontal')
    await a11yAudit()
  })

  test('a decorative separator is hidden from assistive technology, and shows its block', async function (assert) {
    await render(
      <template>
        <nav aria-label="Breadcrumb">
          <ol>
            <li><a href="#home">Home</a></li>
            <Separator @as="li" @decorative={{true}} @name="slash">/</Separator>
            <li>Docs</li>
          </ol>
        </nav>
        <Separator @decorative={{true}} @name="rule">ignored</Separator>
        <Separator @as="span" @name="semantic">ignored</Separator>
      </template>,
    )
    const slash = new SeparatorHarness('slash')
    assert
      .dom(slash.element)
      .hasTagName('li')
      .hasText('/')
      .hasAttribute('role', 'none')
      .hasAttribute('aria-hidden', 'true')
      .doesNotHaveAttribute('aria-orientation')
      .hasAttribute('data-orientation', 'horizontal')
    assert.true(slash.isDecorative)
    assert.strictEqual(slash.role, 'none')

    const rule = new SeparatorHarness('rule')
    assert.dom(rule.element).hasTagName('hr').hasText('', 'an <hr> is void: nothing inside')
    assert.true(rule.isDecorative)
    assert
      .dom(new SeparatorHarness('semantic').element)
      .hasText('', "a semantic separator's content isn't read, so it isn't shown")
    await a11yAudit()
  })

  test('it follows its arguments', async function (assert) {
    class State {
      @tracked orientation: SeparatorOrientation = 'horizontal'
      @tracked decorative = false
    }
    const state = new State()
    await render(
      <template>
        <Separator @as="div" @orientation={{state.orientation}} @decorative={{state.decorative}} />
      </template>,
    )
    const separator = new SeparatorHarness()
    state.orientation = 'vertical'
    await settled()
    assert.strictEqual(separator.orientation, 'vertical')
    assert.dom(separator.element).hasAttribute('aria-orientation', 'vertical')
    state.decorative = true
    await settled()
    assert.true(separator.isDecorative)
    assert.dom(separator.element).doesNotHaveAttribute('aria-orientation')
    assert.strictEqual(separator.orientation, 'vertical', 'from data-orientation')
    await a11yAudit()
  })

  test("separatorAria() is what it renders, for an element of one's own", async function (assert) {
    assert.deepEqual(separatorAria(), {
      role: 'separator',
      'aria-orientation': undefined,
      'aria-hidden': undefined,
      'data-orientation': 'horizontal',
    })
    assert.deepEqual(separatorAria({ tag: 'HR', orientation: 'vertical' }), {
      role: undefined,
      'aria-orientation': 'vertical',
      'aria-hidden': undefined,
      'data-orientation': 'vertical',
    })
    assert.deepEqual(separatorAria({ decorative: true, orientation: 'vertical' }), {
      role: 'none',
      'aria-orientation': undefined,
      'aria-hidden': 'true',
      'data-orientation': 'vertical',
    })
    await a11yAudit()
  })

  test('the harness says which separator it is pointed at', async function (assert) {
    await render(<template><Separator @name="one" /></template>)
    assert.throws(() => new SeparatorHarness('two').element, /no separator "two" found/)
    await a11yAudit()
  })
})
