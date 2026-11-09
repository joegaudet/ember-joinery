import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { LabelHarness, SwitchHarness } from '@ember-joinery/test-support'
import SwitchDemo from 'docs-app/examples/switch-demo'

module('Example | switch-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('an airplane mode switch, which its label toggles', async function (assert) {
    await render(<template><SwitchDemo /></template>)
    const airplane = new SwitchHarness()
    const label = new LabelHarness()

    assert.strictEqual(airplane.label, 'Airplane Mode')
    assert.strictEqual(label.control, airplane.element, 'the Label names the switch')
    assert.strictEqual(airplane.size, 'default')
    assert.false(airplane.isChecked)
    await airplane.toggle()
    assert.true(airplane.isChecked)
    await label.click()
    assert.false(airplane.isChecked, 'a click on the label toggles it')
    await a11yAudit()
  })
})
