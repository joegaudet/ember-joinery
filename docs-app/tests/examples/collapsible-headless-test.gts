import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CollapsibleHarness } from '@ember-joinery/test-support'
import CollapsibleHeadless from 'docs-app/examples/collapsible-headless'

module('Example | collapsible-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('a disclosure styled by its own CSS, animated from the measured height', async function (assert) {
    await render(<template><CollapsibleHeadless /></template>)
    const disclosure = new CollapsibleHarness()
    assert.strictEqual(disclosure.label, 'Can I use this in my project? +')
    assert.true(disclosure.controlsContent)

    await disclosure.open()
    assert.strictEqual(disclosure.label, 'Can I use this in my project? −')
    assert.strictEqual(
      disclosure.text,
      'Yes. Free to use for personal and commercial projects. No attribution required.',
    )
    assert.ok(
      disclosure.content!.style.getPropertyValue('--radix-collapsible-content-height'),
      'measured for the animation',
    )

    await disclosure.close()
    assert.false(disclosure.isShown, 'hidden once its closing animation ends')
    await a11yAudit()
  })
})
