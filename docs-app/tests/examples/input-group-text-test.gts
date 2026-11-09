import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InputGroupHarness } from '@ember-joinery/test-support'
import InputGroupTextExample from 'docs-app/examples/input-group-text'

module('Example | input-group-text', function (hooks) {
  setupRenderingTest(hooks)

  test('text before and after the input, and below a textarea', async function (assert) {
    await render(<template><InputGroupTextExample /></template>)
    const [price, url, username, message] = InputGroupHarness.findAll()
    assert.deepEqual(price!.texts, ['$', 'USD'])
    assert.deepEqual(url!.texts, ['https://', '.com'])
    assert.strictEqual(
      getComputedStyle(url!.control).paddingLeft,
      '2px',
      'pl-0.5!: the domain starts right after https://',
    )
    assert.deepEqual(username!.texts, ['@company.com'])
    assert.strictEqual(message!.control.tagName, 'TEXTAREA')
    assert.deepEqual(message!.texts, ['120 characters left'])
    assert.strictEqual(getComputedStyle(message!.part('text')).fontSize, '12px', 'text-xs')
    await url!.fillIn('shadcn')
    assert.strictEqual(url!.value, 'shadcn')
    await a11yAudit()
  })
})
