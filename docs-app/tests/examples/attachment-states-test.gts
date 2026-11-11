import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AttachmentHarness } from '@ember-joinery/test-support'
import AttachmentStates from 'docs-app/examples/attachment-states'

/**
 * Upstream draws a failed upload's description `--destructive` at 80% (Rhea's and Nova's
 * alike), under the 4.5:1 WCAG AA asks of its 12px text; the Attachment page's Accessibility
 * notes say how an app can darken it. So one audit runs every rule but colour contrast, and the
 * other checks the contrast of everything else.
 */
const ALL_BUT_CONTRAST = { rules: { 'color-contrast': { enabled: false } } }
const BUT_THE_ERROR = {
  include: [['#ember-testing-container']],
  exclude: [['[data-slot="attachment"][data-state="error"] [data-slot="attachment-description"]']],
}

module('Example | attachment-states', function (hooks) {
  setupRenderingTest(hooks)

  test('each upload state, said in words as well as by its look', async function (assert) {
    await render(<template><AttachmentStates /></template>)
    const attachments = AttachmentHarness.findAll()
    assert.deepEqual(
      attachments.map(attachment => [attachment.state, attachment.description]),
      [
        ['idle', 'Ready to upload'],
        ['uploading', 'Uploading · 64%'],
        ['processing', 'Processing document'],
        ['error', 'Upload failed. Try again.'],
        ['done', 'Uploaded · 1.8 MB'],
      ],
    )
    assert.deepEqual(
      attachments.map(attachment => attachment.isBusy),
      [false, true, true, false, false],
    )
    const failed = attachments[3]!
    assert.true(failed.isError)
    assert.deepEqual(failed.actionLabels, ['Retry upload', 'Remove financial-model.xlsx'])
    await a11yAudit(ALL_BUT_CONTRAST)
    await a11yAudit(BUT_THE_ERROR, { runOnly: ['color-contrast'] })
  })
})
