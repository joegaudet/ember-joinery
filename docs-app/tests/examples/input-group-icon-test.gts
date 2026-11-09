import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { InputGroupHarness } from '@ember-joinery/test-support'
import InputGroupIcon from 'docs-app/examples/input-group-icon'

module('Example | input-group-icon', function (hooks) {
  setupRenderingTest(hooks)

  test('icons at the start, at the end, and two together', async function (assert) {
    await render(<template><InputGroupIcon /></template>)
    const [search, email, card, starred] = InputGroupHarness.findAll()
    assert.strictEqual(search!.placeholder, 'Search...')
    assert.strictEqual(email!.control.type, 'email')
    assert.deepEqual(card!.aligns, ['inline-start', 'inline-end'])
    assert.deepEqual(starred!.aligns, ['inline-end'])
    assert.strictEqual(starred!.icons.length, 2, 'a star and an info icon in one addon')
    for (const icon of starred!.icons) {
      assert.strictEqual(getComputedStyle(icon).width, '16px', 'size-4')
      assert.dom(icon).hasAttribute('aria-hidden', 'true')
    }
    const [star, info] = starred!.icons.map(icon => icon.getBoundingClientRect())
    assert.ok(star!.right < info!.left, 'side by side, with a gap')
    await a11yAudit()
  })
})
