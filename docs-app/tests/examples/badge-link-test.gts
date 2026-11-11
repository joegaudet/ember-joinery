import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { getRootElement, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BadgeHarness, IconHarness } from '@ember-joinery/test-support'
import BadgeLink from 'docs-app/examples/badge-link'

module('Example | badge-link', function (hooks) {
  setupRenderingTest(hooks)

  test('a link that looks like a badge, with an icon at its end', async function (assert) {
    await render(<template><BadgeLink /></template>)
    const link = new BadgeHarness()
    assert.dom(link.element).hasTagName('a')
    assert.true(link.isLink)
    assert.strictEqual(link.href, '#link')
    assert.strictEqual(link.text, 'Open Link')
    assert.strictEqual(link.variant, 'default')
    assert.strictEqual(
      getRootElement().textContent!.trim(),
      'Open Link',
      'the link and nothing else',
    )
    assert.strictEqual(getComputedStyle(link.element).display, 'inline-flex', 'styled as a badge')
    assert.strictEqual(getComputedStyle(link.element).paddingRight, '6px', 'the icon is at its end')

    await link.focus()
    assert.true(link.isFocused, 'a link is in the tab order')
    assert.true(link.find(IconHarness).isDecorative)
    await a11yAudit()
  })
})
