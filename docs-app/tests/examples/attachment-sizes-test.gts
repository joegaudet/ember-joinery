import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AttachmentHarness } from '@ember-joinery/test-support'
import AttachmentSizes from 'docs-app/examples/attachment-sizes'

module('Example | attachment-sizes', function (hooks) {
  setupRenderingTest(hooks)

  test('the three sizes, each smaller than the last', async function (assert) {
    await render(<template><AttachmentSizes /></template>)
    const [standard, small, tiny] = AttachmentHarness.findAll()
    assert.deepEqual(
      [standard!, small!, tiny!].map(attachment => [attachment.size, attachment.title]),
      [
        ['default', 'Default attachment'],
        ['sm', 'Small attachment'],
        ['xs', 'Extra small attachment'],
      ],
    )
    assert.strictEqual(tiny!.description, '', 'the smallest shows a title only')
    const width = (attachment: AttachmentHarness) => attachment.media.offsetWidth
    assert.true(width(standard!) > width(small!) && width(small!) > width(tiny!))
    await a11yAudit()
  })
})
