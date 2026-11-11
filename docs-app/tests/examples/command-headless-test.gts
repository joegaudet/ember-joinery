import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CommandHarness } from '@ember-joinery/test-support'
import CommandHeadless from 'docs-app/examples/command-headless'

module('Example | command-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('a search box over the pages: keywords match, and the count is announced', async function (assert) {
    await render(<template><CommandHeadless /></template>)
    const docs = new CommandHarness()
    assert.dom(docs.input).hasAttribute('aria-labelledby', docs.part('label').id)
    assert.strictEqual(docs.status, '4 results')
    await a11yAudit()

    await docs.search('window')
    assert.deepEqual(docs.itemValues, ['Dialog'], 'its keywords find it')
    assert.strictEqual(docs.status, '1 result')
    await docs.press('Enter')
    assert.dom('[data-test-opened]').hasText('Dialog')

    await docs.search('zzz')
    assert.dom(docs.empty).hasText('Nothing matches.')
    assert.strictEqual(docs.status, '0 results')
    await a11yAudit()
  })
})
