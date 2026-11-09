import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  BreadcrumbHarness,
  ButtonHarness,
  DropdownMenuHarness,
  child,
} from '@ember-joinery/test-support'
import BreadcrumbDemo from 'docs-app/examples/breadcrumb-demo'

/** The breadcrumb, with the menu its collapsed crumbs are in. */
class CollapsedBreadcrumb extends BreadcrumbHarness {
  @child(DropdownMenuHarness) declare menu: DropdownMenuHarness
}

module('Example | breadcrumb-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('the collapsed crumbs are in a menu, behind a ghost button', async function (assert) {
    await render(<template><BreadcrumbDemo /></template>)
    const breadcrumb = new CollapsedBreadcrumb()
    assert.deepEqual(breadcrumb.links, ['Home', 'Components'])
    assert.strictEqual(breadcrumb.current, 'Breadcrumb')
    const button = new ButtonHarness({ within: breadcrumb })
    assert
      .dom('[data-slot="breadcrumb-ellipsis"]', button.element)
      .exists('the ellipsis is the button')
    // Its name is its hidden "Toggle menu": the ellipsis inside, "More" and all, is aria-hidden.
    assert.dom('.sr-only', button.element).hasText('Toggle menu')
    assert
      .dom('[data-slot="breadcrumb-ellipsis"]', button.element)
      .hasAttribute('aria-hidden', 'true')
    assert.strictEqual(button.variant, 'ghost')
    assert.strictEqual(button.size, 'icon-sm')
    assert.strictEqual(breadcrumb.menu.trigger, button.element)
    await a11yAudit()

    await breadcrumb.menu.open()
    assert.deepEqual(breadcrumb.menu.items, ['Documentation', 'Themes', 'GitHub'])
    assert.strictEqual(breadcrumb.menu.align, 'start')
    await a11yAudit()
    await breadcrumb.menu.select('Themes')
    assert.false(breadcrumb.menu.isOpen)
    assert.true(button.isFocused)
    await a11yAudit()
  })
})
