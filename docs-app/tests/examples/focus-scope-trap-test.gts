import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, fillIn, focus, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, tab } from '@ember-joinery/test-support'
import FocusScopeTrap from 'docs-app/examples/focus-scope-trap'

/** The example: a profile, an Edit button, and the trapped panel it opens. */
class ProfileEditorHarness extends Harness {
  static component = 'profile-editor'

  get summary() {
    return this.part('summary').textContent!.trim()
  }

  get editButton() {
    return this.part('edit')
  }

  get isOpen() {
    return this.queryPart('panel') !== null
  }

  field(name: 'name' | 'username' | 'cancel' | 'save') {
    return this.part(name)
  }

  async edit() {
    await click(this.editButton)
  }
}

module('Example | focus-scope-trap', function (hooks) {
  setupRenderingTest(hooks)

  test('focus moves in, Tab goes round inside, and focus returns on close', async function (assert) {
    await render(<template><FocusScopeTrap /></template>)
    const editor = new ProfileEditorHarness()
    await editor.edit()
    assert.true(editor.isOpen)
    assert.dom(editor.field('name')).isFocused('focus moves to the first field')

    await tab()
    assert.dom(editor.field('username')).isFocused()
    await tab()
    await tab()
    assert.dom(editor.field('save')).isFocused()
    await tab()
    assert.dom(editor.field('name')).isFocused('Tab from the last goes round to the first')
    await tab({ shift: true })
    assert.dom(editor.field('save')).isFocused('and Shift+Tab back to the last')

    await focus(editor.editButton)
    assert.dom(editor.field('save')).isFocused('focus can’t leave while it is open')

    await click(editor.field('cancel'))
    assert.false(editor.isOpen)
    assert.dom(editor.editButton).isFocused('focus returns to the button that opened it')
    await a11yAudit()
  })

  test('saving closes it too, and returns focus', async function (assert) {
    await render(<template><FocusScopeTrap /></template>)
    const editor = new ProfileEditorHarness()
    await editor.edit()
    await fillIn(editor.field('username'), 'countess')
    await click(editor.field('save'))
    assert.strictEqual(editor.summary, 'Ada Lovelace (@countess)')
    assert.dom(editor.editButton).isFocused()
    await a11yAudit()
  })
})
