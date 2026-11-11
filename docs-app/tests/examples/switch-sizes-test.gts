import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SwitchHarness } from '@ember-joinery/test-support'
import SwitchSizes from 'docs-app/examples/switch-sizes'

module('Example | switch-sizes', function (hooks) {
  setupRenderingTest(hooks)

  test('a small and a default switch', async function (assert) {
    await render(<template><SwitchSizes /></template>)
    const [small, normal] = SwitchHarness.findAll()

    assert.strictEqual(small!.size, 'sm')
    assert.strictEqual(normal!.size, 'default')
    assert.strictEqual(small!.label, 'Small')
    assert.true(
      small!.element.getBoundingClientRect().width < normal!.element.getBoundingClientRect().width,
    )
    await small!.toggle()
    assert.true(small!.isChecked)
    await a11yAudit()
  })
})
