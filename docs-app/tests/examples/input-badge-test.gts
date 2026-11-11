import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BadgeHarness, FieldHarness, InputHarness } from '@ember-joinery/test-support'
import InputBadge from 'docs-app/examples/input-badge'

module('Example | input-badge', function (hooks) {
  setupRenderingTest(hooks)

  test('a Beta badge at the far end of the label', async function (assert) {
    await render(<template><InputBadge /></template>)
    const field = new FieldHarness()
    const badge = field.find(BadgeHarness)
    const url = field.find(InputHarness)

    assert.strictEqual(badge.variant, 'secondary')
    assert.strictEqual(badge.text, 'Beta')
    assert.strictEqual(url.type, 'url')
    assert.strictEqual(url.label, 'Webhook URL Beta')
    assert.strictEqual(
      Math.round(badge.element.getBoundingClientRect().right),
      Math.round(field.labelElement!.getBoundingClientRect().right),
      'ml-auto pushes it to the end',
    )
    await a11yAudit()
  })
})
