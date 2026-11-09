import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { FieldHarness, ProgressHarness } from '@ember-joinery/test-support'
import ProgressLabel from 'docs-app/examples/progress-label'

module('Example | progress-label', function (hooks) {
  setupRenderingTest(hooks)

  test('a bar at 66%, named by the label above it', async function (assert) {
    await render(<template><ProgressLabel /></template>)
    const field = new FieldHarness()
    const upload = field.find(ProgressHarness)

    assert.strictEqual(upload.value, 66)
    assert.strictEqual(upload.label, 'Upload progress 66%')
    assert.strictEqual(field.label, 'Upload progress 66%')
    const [title, percent] = field.labelElement!.querySelectorAll('span')
    assert.strictEqual(
      Math.round(percent!.getBoundingClientRect().right),
      Math.round(field.labelElement!.getBoundingClientRect().right),
      'the percentage at the far end',
    )
    assert.true(title!.getBoundingClientRect().right < percent!.getBoundingClientRect().left)
    await a11yAudit()
  })
})
