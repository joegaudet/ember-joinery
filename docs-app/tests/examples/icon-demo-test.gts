import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { IconHarness } from '@ember-joinery/test-support'
import IconDemo from 'docs-app/examples/icon-demo'

module('Example | icon-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('lucide icons, decorative unless they have a label', async function (assert) {
    await render(<template><IconDemo /></template>)
    const [search, bell, heart, trash] = IconHarness.findAll()

    assert.true(search!.isDecorative)
    assert.dom(search!.element).hasAttribute('width', '24')
    assert.dom(bell!.element).hasAttribute('width', '32').hasAttribute('height', '32')
    assert.dom(heart!.element).hasAttribute('stroke-width', '1.5')
    assert.false(trash!.isDecorative)
    assert.strictEqual(trash!.label, 'Trash')
    assert.dom(trash!.element).hasAttribute('role', 'img')
    await a11yAudit()
  })
})
