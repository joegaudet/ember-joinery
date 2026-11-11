import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BadgeHarness } from '@ember-joinery/test-support'
import BadgeColors from 'docs-app/examples/badge-colors'

module('Example | badge-colors', function (hooks) {
  setupRenderingTest(hooks)

  test('utility classes give each badge its own colours, over the default variant', async function (assert) {
    await render(<template><BadgeColors /></template>)
    const badges = BadgeHarness.findAll()
    assert.deepEqual(
      badges.map(badge => badge.text),
      ['Blue', 'Green', 'Sky', 'Purple', 'Red'],
    )
    const backgrounds = new Set(
      badges.map(badge => getComputedStyle(badge.element).backgroundColor),
    )
    assert.strictEqual(backgrounds.size, 5, 'five fills')
    for (const badge of badges) {
      assert.strictEqual(badge.variant, 'default')
      assert.dom(badge.element).hasClass('jn-badge-variant-default')
    }
    const probe = document.createElement('span')
    probe.style.backgroundColor = 'var(--primary)'
    badges[0]!.element.after(probe)
    assert.notOk(
      backgrounds.has(getComputedStyle(probe).backgroundColor),
      "none is the default variant's --primary: the classes win, as they do upstream",
    )
    probe.remove()
    await a11yAudit()
  })
})
