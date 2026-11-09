import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, DialogHarness, InputHarness, child } from '@ember-joinery/test-support'
import DialogCloseButton from 'docs-app/examples/dialog-close-button'

/** The share dialog: a page object, with its link and its own Close button declared. */
class ShareDialog extends DialogHarness {
  @child(InputHarness) declare link: InputHarness

  /** The footer's Close, a Button of the example's own (not the corner's, also "Close"). */
  get footerClose(): ButtonHarness {
    return this.findAll(ButtonHarness).find(
      button => button.text === 'Close' && button.element !== this.closeButton,
    )!
  }
}

module('Example | dialog-close-button', function (hooks) {
  setupRenderingTest(hooks)

  test('a read-only link to share, and a Close button of its own', async function (assert) {
    await render(<template><DialogCloseButton /></template>)
    const dialog = new ShareDialog()
    assert.dom(dialog.trigger).hasText('Share')
    await dialog.open()
    assert.strictEqual(dialog.label, 'Share link')
    assert.strictEqual(
      dialog.descriptionText,
      'Anyone who has this link will be able to view this.',
    )

    assert.strictEqual(dialog.link.value, 'https://ui.shadcn.com/docs/installation')
    assert.true(dialog.link.isReadOnly)
    assert.strictEqual(dialog.link.label, 'Link', 'its label names it')
    const label = dialog.content!.querySelector('label')!
    assert.strictEqual(label.offsetWidth, 1, 'sr-only: the label is not seen')
    assert.true(dialog.link.isFocused, 'focus goes to the first thing in it, the link')
    assert.notStrictEqual(dialog.closeButton, null, 'the corner close button stays')
    await a11yAudit()

    await dialog.footerClose.click()
    assert.false(dialog.isOpen, "the footer's Close closes it")
    assert.dom(dialog.trigger).isFocused()
    await a11yAudit()
  })
})
