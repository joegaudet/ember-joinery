import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, EmptyHarness, IconHarness } from '@ember-joinery/test-support'
import EmptyBackground from 'docs-app/examples/empty-background'

module('Example | empty-background', function (hooks) {
  setupRenderingTest(hooks)

  test('a muted background, and a refresh button with an icon', async function (assert) {
    await render(<template><EmptyBackground /></template>)
    const empty = new EmptyHarness()
    assert.strictEqual(empty.title, 'No Notifications')
    assert.strictEqual(
      empty.description,
      "You're all caught up. New notifications will appear here.",
    )
    assert.notStrictEqual(
      getComputedStyle(empty.element).backgroundColor,
      'rgba(0, 0, 0, 0)',
      'bg-muted/30',
    )
    assert.strictEqual(
      getComputedStyle(empty.part('description')).maxWidth,
      '320px',
      'max-w-xs on the description',
    )
    const refresh = empty.find(ButtonHarness)
    assert.strictEqual(refresh.label, 'Refresh')
    assert.strictEqual(refresh.variant, 'outline')
    assert.true(refresh.find(IconHarness).isDecorative)
    await a11yAudit()
  })
})
