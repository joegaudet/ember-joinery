import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { FieldHarness, ProgressHarness } from '@ember-joinery/test-support'
import ProgressRtl from 'docs-app/examples/progress-rtl'

module('Example | progress-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('in Arabic, the label at the right and the percentage at the left', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><ProgressRtl /></DirectionProvider>
      </template>,
    )
    const field = new FieldHarness()
    const upload = field.find(ProgressHarness)

    assert.strictEqual(upload.value, 66)
    assert.strictEqual(upload.label, 'تقدم الرفع ٦٦%')
    const [title, percent] = field.labelElement!.querySelectorAll('span')
    assert.true(
      title!.getBoundingClientRect().left > percent!.getBoundingClientRect().right,
      'right to left, the title first',
    )
    await a11yAudit()
  })
})
