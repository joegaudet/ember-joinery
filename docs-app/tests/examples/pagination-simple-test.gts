import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { PaginationHarness } from '@ember-joinery/test-support'
import PaginationSimple from 'docs-app/examples/pagination-simple'

module('Example | pagination-simple', function (hooks) {
  setupRenderingTest(hooks)

  test('five page links and nothing else', async function (assert) {
    await render(<template><PaginationSimple /></template>)
    const pagination = new PaginationHarness()

    assert.deepEqual(pagination.pages, ['1', '2', '3', '4', '5'])
    assert.true(pagination.isCurrent('2'))
    assert.false(pagination.isCurrent('5'))
    assert.false(pagination.hasEllipsis)
    assert.strictEqual(pagination.queryPart('previous'), null, 'no previous link')
    assert.strictEqual(pagination.queryPart('next'), null, 'no next link')
    await a11yAudit()
  })
})
