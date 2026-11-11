import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, SpinnerHarness } from '@ember-joinery/test-support'
import ButtonSpinner from 'docs-app/examples/button-spinner'

module('Example | button-spinner', function (hooks) {
  setupRenderingTest(hooks)

  test('disabled buttons that show they are busy', async function (assert) {
    await render(<template><ButtonSpinner /></template>)
    const [generating, downloading] = ButtonHarness.findAll()

    assert.strictEqual(generating!.label, 'Generating')
    assert.true(generating!.isDisabled)
    assert.strictEqual(generating!.find(SpinnerHarness).label, 'Loading')

    assert.strictEqual(downloading!.label, 'Downloading')
    assert.strictEqual(downloading!.variant, 'secondary')
    assert.true(downloading!.isDisabled)
    assert.strictEqual(downloading!.find(SpinnerHarness).role, 'status')
    await a11yAudit()
  })
})
