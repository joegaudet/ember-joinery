import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, findAll, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import TypographyTable from 'docs-app/examples/typography-table'

// Typography is upstream's own markup, styled with utility classes; there is no component, so
// the test reads the elements and the styles the classes give them.
module('Example | typography-table', function (hooks) {
  setupRenderingTest(hooks)

  test('a bordered table, with every other row shaded', async function (assert) {
    await render(<template><TypographyTable /></template>)
    assert.dom('th').exists({ count: 2 })
    assert.deepEqual(
      findAll('th').map(th => th.textContent!.trim()),
      ["King's Treasury", "People's happiness"],
    )
    assert.dom('tbody tr').exists({ count: 3 })
    const th = getComputedStyle(find('th')!)
    assert.strictEqual(th.fontWeight, '700', 'font-bold')
    assert.strictEqual(th.textAlign, 'left', 'text-left')
    assert.strictEqual(th.borderTopWidth, '1px', 'border')
    assert.strictEqual(th.paddingLeft, '16px', 'px-4')
    assert.strictEqual(th.paddingTop, '8px', 'py-2')
    const [first, second] = findAll('tbody tr')
    assert.notStrictEqual(
      getComputedStyle(second!).backgroundColor,
      getComputedStyle(first!).backgroundColor,
      'even:bg-muted',
    )
    assert.strictEqual(find('table')!.offsetWidth, find('div')!.clientWidth, 'w-full')
    await a11yAudit()
  })
})
