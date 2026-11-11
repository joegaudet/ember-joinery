import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { NativeFormHarness } from '@ember-joinery/test-support'
import NativeFormDemo from 'docs-app/examples/native-form-demo'

module('Example | native-form-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('every change hands over the whole form, shown as JSON', async function (assert) {
    await render(<template><NativeFormDemo /></template>)
    const form = new NativeFormHarness()
    const shown = () => JSON.parse(form.element.parentElement!.querySelector('pre')!.textContent!)

    assert.deepEqual(shown(), { firstName: 'Gwen' })
    await form.fillIn('firstName', 'Miles')
    assert.deepEqual(shown(), { firstName: 'Miles', universe: null })
    await form.choose('universe', '616')
    assert.deepEqual(shown(), { firstName: 'Miles', universe: '616' })
    assert.deepEqual(form.entries, { firstName: 'Miles', universe: '616' })
    await a11yAudit()
  })
})
