import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { hideOthers, inertOthers } from '@ember-joinery/primitives/hide-others'

module('Integration | primitives | hide-others', function (hooks) {
  setupRenderingTest(hooks)

  test('hideOthers hides everything but the target, its ancestors and live regions', async function (assert) {
    await render(
      <template>
        <header data-test-header>Header</header>
        <main data-test-main>
          <nav data-test-nav>Nav</nav>
          <section data-test-target>
            <p data-test-inside>Inside</p>
          </section>
        </main>
        <div aria-live="polite" data-test-live>Saved</div>
      </template>,
    )
    const undo = hideOthers(find('[data-test-target]')!)

    assert.dom('[data-test-header]').hasAttribute('aria-hidden', 'true')
    assert.dom('[data-test-header]').hasAttribute('data-aria-hidden', 'true')
    assert.dom('[data-test-nav]').hasAttribute('aria-hidden', 'true', 'siblings at every level')
    assert.dom('[data-test-main]').doesNotHaveAttribute('aria-hidden', 'not its ancestors')
    assert.dom('[data-test-target]').doesNotHaveAttribute('aria-hidden')
    assert.dom('[data-test-inside]').doesNotHaveAttribute('aria-hidden', 'nor what it holds')
    assert.dom('[data-test-live]').doesNotHaveAttribute('aria-hidden', 'a live region is heard')
    const runner = document.getElementById('qunit')
    if (runner) assert.dom(runner).hasAttribute('aria-hidden', 'true', 'up to <body>')

    undo()
    assert.dom('[data-test-header]').doesNotHaveAttribute('aria-hidden')
    assert.dom('[data-test-header]').doesNotHaveAttribute('data-aria-hidden')
    assert.dom('[data-test-nav]').doesNotHaveAttribute('aria-hidden')
    if (runner) assert.dom(runner).doesNotHaveAttribute('aria-hidden')
    await a11yAudit()
  })

  test('calls stack, and an element hidden before stays hidden', async function (assert) {
    await render(
      <template>
        <div data-test-hidden aria-hidden="true">Hidden already</div>
        <div data-test-other>Other</div>
        <section data-test-a>A</section>
        <section data-test-b>B</section>
      </template>,
    )
    const first = hideOthers(find('[data-test-a]')!)
    const second = hideOthers([find('[data-test-a]'), find('[data-test-b]')])
    assert.dom('[data-test-other]').hasAttribute('aria-hidden', 'true')

    first()
    assert.dom('[data-test-other]').hasAttribute('aria-hidden', 'true', 'the second still hides it')
    assert.dom('[data-test-b]').doesNotHaveAttribute('aria-hidden')
    second()
    assert.dom('[data-test-other]').doesNotHaveAttribute('aria-hidden')
    assert.dom('[data-test-hidden]').hasAttribute('aria-hidden', 'true', 'its own stays')
    second()
    assert
      .dom('[data-test-hidden]')
      .hasAttribute('aria-hidden', 'true', 'undoing twice does nothing')
    await a11yAudit()
  })

  test('inertOthers makes the rest inert, as a modal <dialog> does', async function (assert) {
    await render(
      <template>
        <button type="button" data-test-outside>Outside</button>
        <div data-test-already inert>Inert already</div>
        <div aria-live="polite" data-test-live>Saved</div>
        <section data-test-target>
          <button type="button" data-test-inside>Inside</button>
        </section>
      </template>,
    )
    const undo = inertOthers([find('[data-test-target]'), null])
    const outside = find('[data-test-outside]') as HTMLButtonElement

    assert.dom(outside).hasAttribute('inert', '').hasAttribute('data-inert-ed', 'true')
    outside.focus()
    assert.dom(outside).isNotFocused('an inert element takes no focus')
    assert.dom('[data-test-inside]').doesNotHaveAttribute('inert')
    assert.dom('[data-test-live]').doesNotHaveAttribute('inert')

    undo()
    assert.dom(outside).doesNotHaveAttribute('inert')
    assert.dom(outside).doesNotHaveAttribute('data-inert-ed')
    assert.dom('[data-test-already]').hasAttribute('inert', '', 'its own stays')
    outside.focus()
    assert.dom(outside).isFocused()
    await a11yAudit()
  })

  test('a parent limits what is hidden', async function (assert) {
    await render(
      <template>
        <div data-test-outside>Outside</div>
        <div data-test-parent>
          <p data-test-sibling>Sibling</p>
          <p data-test-target>Target</p>
        </div>
      </template>,
    )
    const undo = hideOthers(find('[data-test-target]')!, { parent: find('[data-test-parent]')! })
    assert.dom('[data-test-sibling]').hasAttribute('aria-hidden', 'true')
    assert
      .dom('[data-test-outside]')
      .doesNotHaveAttribute('aria-hidden', 'outside the parent: left')
    undo()
    await a11yAudit()
  })
})
