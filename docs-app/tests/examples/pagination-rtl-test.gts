import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { PaginationHarness } from '@ember-joinery/test-support'
import PaginationRtl from 'docs-app/examples/pagination-rtl'

module('Example | pagination-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('Arabic numerals, right to left, with the arrows mirrored', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><PaginationRtl /></DirectionProvider>
      </template>,
    )
    const pagination = new PaginationHarness()

    assert.deepEqual(pagination.pages, ['١', '٢', '٣'])
    assert.strictEqual(pagination.current, '٢')
    assert.dom(pagination.previous).hasText('السابق').hasAttribute('aria-label', 'انتقل إلى السابق')
    assert.dom(pagination.next).hasText('التالي').hasAttribute('aria-label', 'انتقل إلى التالي')
    assert.ok(
      pagination.previous.getBoundingClientRect().left >
        pagination.next.getBoundingClientRect().left,
      'previous is on the right',
    )
    const arrow = pagination.previous.querySelector('svg')!
    assert.strictEqual(getComputedStyle(arrow).rotate, '180deg', 'its arrow points right')
    await a11yAudit()
  })
})
