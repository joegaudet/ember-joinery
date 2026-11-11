import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { KbdGroupHarness } from '@ember-joinery/test-support'
import KbdRtl from 'docs-app/examples/kbd-rtl'

/**
 * The audit, but for the contrast of the keys' own text: upstream's keys draw
 * `--muted-foreground` on `--muted`, under the 4.5:1 WCAG AA asks of 12px text (see the Kbd
 * page's Accessibility notes). Everything around them is audited.
 */
const BUT_THE_KEYS = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="kbd"]']],
}

module('Example | kbd-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, the keys run from the right', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><KbdRtl /></DirectionProvider>
      </template>,
    )
    const [modifiers, shortcut] = KbdGroupHarness.findAll()
    assert.deepEqual(modifiers!.keys, ['⌘', '⇧', '⌥', '⌃'])
    const [command, shift] = modifiers!.kbds
    assert.ok(
      command!.element.getBoundingClientRect().left > shift!.element.getBoundingClientRect().left,
      '⌘, the first, is on the right',
    )
    const [ctrl, b] = shortcut!.kbds
    assert.ok(
      ctrl!.element.getBoundingClientRect().left > b!.element.getBoundingClientRect().left,
      'Ctrl is on the right, B on the left',
    )
    await a11yAudit(BUT_THE_KEYS)
  })
})
