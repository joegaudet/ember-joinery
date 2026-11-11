import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { PaginationHarness } from '@ember-joinery/test-support'
import PaginationDemo from 'docs-app/examples/pagination-demo'

module('Example | pagination-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('three pages, the second current, more after, and previous and next', async function (assert) {
    await render(<template><PaginationDemo /></template>)
    const pagination = new PaginationHarness()

    assert.strictEqual(pagination.label, 'pagination')
    assert.deepEqual(pagination.pages, ['1', '2', '3'])
    assert.strictEqual(pagination.current, '2')
    assert.strictEqual(pagination.page('2').getAttribute('data-variant'), 'outline')
    assert.strictEqual(pagination.page('1').getAttribute('data-variant'), 'ghost')
    assert.true(pagination.hasEllipsis)
    assert
      .dom(pagination.previous)
      .hasAttribute('aria-label', 'Go to previous page')
      .hasText('Previous')
    assert.dom(pagination.next).hasAttribute('aria-label', 'Go to next page').hasText('Next')
    await a11yAudit()
  })
})
