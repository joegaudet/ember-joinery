import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { isMac } from '@ember-joinery/primitives/keys'
import { KeyComboHarness, KeyHarness } from '@ember-joinery/test-support'
import KeysShortcuts from 'docs-app/examples/keys-shortcuts'

module('Example | keys-shortcuts', function (hooks) {
  setupRenderingTest(hooks)

  test('keys and shortcuts render as <kbd>, with the Mac’s keys on a Mac', async function (assert) {
    await render(<template><KeysShortcuts /></template>)
    assert.strictEqual(new KeyHarness('escape').label, 'Esc')

    const search = new KeyComboHarness('search')
    assert.deepEqual(search.keys, isMac() ? ['⌘', 'K'] : ['Ctrl', 'K'])
    assert.deepEqual(search.separators, ['+'])
    await a11yAudit()
  })
})
