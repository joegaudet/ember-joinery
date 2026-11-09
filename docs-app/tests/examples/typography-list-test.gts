import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, findAll, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import TypographyList from 'docs-app/examples/typography-list'

// Typography is upstream's own markup, styled with utility classes; there is no component, so
// the test reads the elements and the styles the classes give them.
module('Example | typography-list', function (hooks) {
  setupRenderingTest(hooks)

  test('a bulleted list', async function (assert) {
    await render(<template><TypographyList /></template>)
    assert.deepEqual(
      findAll('li').map(li => li.textContent!.trim()),
      [
        '1st level of puns: 5 gold coins',
        '2nd level of jokes: 10 gold coins',
        '3rd level of one-liners : 20 gold coins',
      ],
    )
    const style = getComputedStyle(find('ul')!)
    assert.strictEqual(style.listStyleType, 'disc', 'list-disc')
    assert.strictEqual(style.marginLeft, '24px', 'ml-6')
    assert.strictEqual(getComputedStyle(find('li')!).marginTop, '8px', '[&>li]:mt-2')
    await a11yAudit()
  })
})
