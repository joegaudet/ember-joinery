import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { getRootElement, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { KbdGroupHarness } from '@ember-joinery/test-support'
import KbdGroupExample from 'docs-app/examples/kbd-group'

/**
 * The audit, but for the contrast of the keys' own text: upstream's keys draw
 * `--muted-foreground` on `--muted`, under the 4.5:1 WCAG AA asks of 12px text (see the Kbd
 * page's Accessibility notes). Everything around them is audited.
 */
const BUT_THE_KEYS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="kbd"]']],
}

module('Example | kbd-group', function (hooks) {
  setupRenderingTest(hooks)

  test('two shortcuts in a line of text', async function (assert) {
    await render(<template><KbdGroupExample /></template>)
    const group = new KbdGroupHarness()
    assert.deepEqual(group.keys, ['Ctrl + B', 'Ctrl + K'])
    assert.strictEqual(
      getRootElement().textContent!.replace(/\s+/g, ' ').trim(),
      'Use Ctrl + B Ctrl + K to open the command palette',
    )
    assert.strictEqual(getComputedStyle(group.element).display, 'inline-flex', 'in the line')
    await a11yAudit(BUT_THE_KEYS)
  })
})
