import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { array } from '@ember/helper'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Key, KeyCombo, isMac } from '@ember-joinery/primitives/keys'
import { KeyComboHarness, KeyHarness } from '@ember-joinery/test-support'

/** Makes the page look like it runs on a Mac, or not, until the test ends. */
function emulatePlatform(hooks: { afterEach(callback: () => void): void }) {
  let restore: (() => void) | undefined
  hooks.afterEach(() => restore?.())
  return (mac: boolean) => {
    restore?.()
    const userAgent = mac
      ? 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/537.36'
      : 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
    Object.defineProperty(navigator, 'userAgent', { value: userAgent, configurable: true })
    Object.defineProperty(navigator, 'userAgentData', {
      value: { platform: mac ? 'macOS' : 'Linux' },
      configurable: true,
    })
    restore = () => {
      // The own properties shadow the real ones on Navigator.prototype; removing them restores them.
      delete (navigator as unknown as Record<string, unknown>)['userAgent']
      delete (navigator as unknown as Record<string, unknown>)['userAgentData']
      restore = undefined
    }
  }
}

module('Integration | primitives | keys', function (hooks) {
  setupRenderingTest(hooks)
  const platform = emulatePlatform(hooks)

  test('Key renders a kbd', async function (assert) {
    await render(
      <template>
        <p>Press <Key @name="escape" class="mine">Esc</Key> to close.</p>
      </template>,
    )
    const key = new KeyHarness('escape')
    assert.dom(key.element).hasTagName('kbd').hasClass('mine').hasAttribute('data-slot', 'key')
    assert.strictEqual(key.label, 'Esc')
    await a11yAudit()
  })

  test('KeyCombo renders each key, with separators between', async function (assert) {
    platform(false)
    await render(
      <template>
        <KeyCombo @name="save" @keys="ctrl+s" />
        <KeyCombo @name="list" @keys={{array "Shift" "Alt" "N"}} @separator="then" />
      </template>,
    )
    const save = new KeyComboHarness('save')
    assert.deepEqual(save.keys, ['ctrl', 's'], 'a + string is split into keys')
    assert.deepEqual(save.separators, ['+'])
    assert.strictEqual(save.label, 'ctrl + s')
    assert.deepEqual(
      save.keyHarnesses.map(key => key.label),
      ['ctrl', 's'],
      'each key is a Key',
    )

    const list = new KeyComboHarness('list')
    assert.deepEqual(list.keys, ['Shift', 'Alt', 'N'], 'an array is used as given')
    assert.deepEqual(list.separators, ['then', 'then'], '@separator replaces +')
    await a11yAudit()
  })

  test('KeyCombo shows @mac on a Mac, and @keys elsewhere', async function (assert) {
    platform(true)
    assert.true(isMac())
    await render(<template><KeyCombo @keys="ctrl+k" @mac="⌘+k" /></template>)
    assert.deepEqual(new KeyComboHarness().keys, ['⌘', 'k'])

    platform(false)
    assert.false(isMac())
    await render(<template><KeyCombo @keys="ctrl+k" @mac="⌘+k" /></template>)
    assert.deepEqual(new KeyComboHarness().keys, ['ctrl', 'k'])

    platform(true)
    await render(<template><KeyCombo @keys="ctrl+k" /></template>)
    assert.deepEqual(new KeyComboHarness().keys, ['ctrl', 'k'], 'without @mac, @keys everywhere')
  })
})
