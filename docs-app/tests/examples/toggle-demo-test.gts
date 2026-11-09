import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ToggleHarness, IconHarness } from '@ember-joinery/test-support'
import ToggleDemo from 'docs-app/examples/toggle-demo'

module('Example | toggle-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('a small outline toggle whose bookmark fills when it is on', async function (assert) {
    await render(<template><ToggleDemo /></template>)
    const toggle = new ToggleHarness()
    assert.strictEqual(toggle.label, 'Toggle bookmark')
    assert.strictEqual(toggle.variant, 'outline')
    assert.strictEqual(toggle.size, 'sm')
    const icon = toggle.find(IconHarness).element
    const empty = getComputedStyle(icon).fill
    await toggle.toggle()
    assert.true(toggle.isPressed)
    assert.notStrictEqual(
      getComputedStyle(icon).fill,
      empty,
      'group-data-[state=on]/toggle:fill-foreground',
    )
    await a11yAudit()
  })
})
