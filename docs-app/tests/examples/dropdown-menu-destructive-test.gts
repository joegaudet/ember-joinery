import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, DropdownMenuHarness } from '@ember-joinery/test-support'
import DropdownMenuDestructive from 'docs-app/examples/dropdown-menu-destructive'

/** The colour a token resolves to, as computed styles report colours. */
function token(name: string): string {
  const probe = document.createElement('div')
  probe.style.setProperty('color', `var(${name})`)
  document.querySelector('[data-style]')!.append(probe)
  const color = getComputedStyle(probe).color
  probe.remove()
  return color
}

module('Example | dropdown-menu-destructive', function (hooks) {
  setupRenderingTest(hooks)

  test('Delete is set apart, in the destructive colour', async function (assert) {
    await render(<template><DropdownMenuDestructive /></template>)
    const menu = new DropdownMenuHarness()
    assert.strictEqual(new ButtonHarness().label, 'Actions')
    await menu.open()
    assert.deepEqual(menu.items, ['Edit', 'Share', 'Delete'])
    assert.strictEqual(menu.separators, 1)
    assert.strictEqual(menu.variant('Delete'), 'destructive')
    assert.strictEqual(getComputedStyle(menu.item('Delete')).color, token('--destructive'))
    assert.strictEqual(menu.variant('Edit'), 'default')
    await a11yAudit()
  })
})
