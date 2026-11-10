import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AttachmentGroupHarness, tab } from '@ember-joinery/test-support'
import AttachmentImage from 'docs-app/examples/attachment-image'

module('Example | attachment-image', function (hooks) {
  setupRenderingTest(hooks)

  test('image attachments that open their image, with an action of their own each', async function (assert) {
    await render(<template><AttachmentImage /></template>)
    const [workspace, desk, office] = new AttachmentGroupHarness().attachments
    for (const image of [workspace!, desk!, office!]) {
      assert.strictEqual(image.orientation, 'vertical')
      assert.strictEqual(image.mediaVariant, 'image')
      assert.dom(image.trigger).hasTagName('a').hasAttribute('target', '_blank')
      assert.strictEqual(image.href, image.image!.getAttribute('src'), 'it links to the image')
    }
    assert.strictEqual(workspace!.triggerLabel, 'Open workspace.png')
    assert.deepEqual(desk!.actionLabels, ['Remove desk-reference.jpg'])

    // The action comes before the link, and each stays reachable.
    await tab()
    assert.dom(workspace!.actions[0]!.element).isFocused()
    await tab()
    assert.dom(workspace!.trigger).isFocused()
    await a11yAudit()
  })
})
