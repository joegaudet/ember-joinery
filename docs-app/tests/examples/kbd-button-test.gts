import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, KbdHarness } from '@ember-joinery/test-support'
import KbdButton from 'docs-app/examples/kbd-button'

/**
 * The audit, but for the contrast of the key's own text: upstream's keys draw
 * `--muted-foreground` on `--muted`, under the 4.5:1 WCAG AA asks of 12px text (see the Kbd
 * page's Accessibility notes). The button around it is audited.
 */
const BUT_THE_KEYS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="kbd"]']],
}

module('Example | kbd-button', function (hooks) {
  setupRenderingTest(hooks)

  test('a button with its shortcut key at its end', async function (assert) {
    await render(<template><KbdButton /></template>)
    const accept = new ButtonHarness()
    assert.strictEqual(accept.label, 'Accept ⏎')
    assert.strictEqual(accept.variant, 'outline')
    const key = accept.find(KbdHarness)
    assert.strictEqual(key.label, '⏎')
    const box = accept.element.getBoundingClientRect()
    assert.ok(key.element.getBoundingClientRect().left > box.left + box.width / 2, 'at the end')
    // has-data-[icon=inline-end]:pe-2, and the key nudged along with translate-x-0.5.
    assert.strictEqual(getComputedStyle(accept.element).paddingRight, '8px')
    assert.ok(getComputedStyle(key.element).translate.startsWith('2px'), 'translate-x-0.5')
    assert.strictEqual(
      getComputedStyle(key.element).pointerEvents,
      'none',
      'a press on the key is a press on the button',
    )
    await a11yAudit(BUT_THE_KEYS)
  })
})
