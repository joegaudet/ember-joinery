import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InputGroupHarness, SpinnerHarness } from '@ember-joinery/test-support'
import InputGroupSpinner from 'docs-app/examples/input-group-spinner'

module('Example | input-group-spinner', function (hooks) {
  setupRenderingTest(hooks)

  test('spinners and a turning icon beside the input, with text', async function (assert) {
    await render(<template><InputGroupSpinner /></template>)
    const [searching, processing, saving, refreshing] = InputGroupHarness.findAll()
    assert.deepEqual(searching!.aligns, ['inline-end'])
    assert.strictEqual(searching!.find(SpinnerHarness).label, 'Loading')
    assert.deepEqual(processing!.aligns, ['inline-start'])
    assert.deepEqual(saving!.texts, ['Saving...'])
    assert.true(saving!.find(SpinnerHarness).exists)
    assert.deepEqual(refreshing!.texts, ['Please wait...'])
    const loader = refreshing!.icons[0]!
    assert.notStrictEqual(getComputedStyle(loader).animationName, 'none', 'animate-spin')
    await a11yAudit()
  })
})
