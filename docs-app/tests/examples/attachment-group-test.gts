import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AttachmentGroupHarness } from '@ember-joinery/test-support'
import AttachmentGroupDemo from 'docs-app/examples/attachment-group'

module('Example | attachment-group', function (hooks) {
  setupRenderingTest(hooks)

  test('a row that scrolls across, to an attachment out of sight when its action takes focus', async function (assert) {
    await render(<template><AttachmentGroupDemo /></template>)
    const group = new AttachmentGroupHarness()
    assert.deepEqual(group.titles, [
      'briefing-notes.pdf',
      'workspace.png',
      'customers.csv',
      'renderer.tsx',
    ])
    assert.deepEqual(
      group.attachments.map(attachment => attachment.mediaVariant),
      ['icon', 'image', 'icon', 'icon'],
    )
    assert.true(group.isScrollable, 'four wide cards in a narrow row')
    assert.strictEqual(group.scrollOffset, 0)
    const last = group.attachments.at(-1)!
    assert.deepEqual(last.actionLabels, ['Remove renderer.tsx'])
    await last.actions[0]!.focus()
    await settled()
    assert.true(group.scrollOffset > 0, 'the row scrolled to it')
    await a11yAudit()
  })
})
