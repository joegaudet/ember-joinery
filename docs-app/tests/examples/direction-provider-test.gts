import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import DirectionProviderExample from 'docs-app/examples/direction-provider'

module('Example | direction-provider', function (hooks) {
  setupRenderingTest(hooks)

  test('content inside reads the provider’s direction from the document', async function (assert) {
    await render(<template><DirectionProviderExample /></template>)
    assert.dom('[data-slot="direction-provider"]').hasAttribute('dir', 'rtl')
    assert.strictEqual(getComputedStyle(find('.direction-card')!).direction, 'rtl')

    await click('.direction-card button')
    assert.dom('output').hasText('getDirection() → rtl')

    await click('button')
    assert.dom('[data-slot="direction-provider"]').hasAttribute('dir', 'ltr')
    await click('.direction-card button')
    assert.dom('output').hasText('getDirection() → ltr')
    await a11yAudit()
  })
})
