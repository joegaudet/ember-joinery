import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { KbdGroupHarness } from '@ember-joinery/test-support'
import KbdDemo from 'docs-app/examples/kbd-demo'

/**
 * The audit, but for the contrast of the keys' own text: upstream's keys draw
 * `--muted-foreground` on `--muted`, under the 4.5:1 WCAG AA asks of 12px text (see the Kbd
 * page's Accessibility notes). Everything around them is audited.
 */
const BUT_THE_KEYS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="kbd"]']],
}

module('Example | kbd-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('the modifier keys, and a shortcut with a plus between its keys', async function (assert) {
    await render(<template><KbdDemo /></template>)
    const [modifiers, shortcut] = KbdGroupHarness.findAll()
    assert.deepEqual(modifiers!.keys, ['⌘', '⇧', '⌥', '⌃'])
    assert.deepEqual(shortcut!.keys, ['Ctrl', 'B'])
    assert.strictEqual(shortcut!.label, 'Ctrl + B')
    for (const kbd of modifiers!.kbds) {
      assert.strictEqual(getComputedStyle(kbd.element).height, '20px', 'styled: h-5')
    }
    await a11yAudit(BUT_THE_KEYS)
  })
})
