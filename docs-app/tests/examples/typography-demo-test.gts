import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, findAll, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import TypographyDemo from 'docs-app/examples/typography-demo'

// Typography is upstream's own markup, styled with utility classes; there is no component, so
// the test reads the elements and the styles the classes give them.
module('Example | typography-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('the story, with every style on the page', async function (assert) {
    await render(<template><TypographyDemo /></template>)
    assert.deepEqual(
      findAll('h1, h2, h3').map(heading => `${heading.tagName} ${heading.textContent!.trim()}`),
      [
        'H1 Taxing Laughter: The Joke Tax Chronicles',
        "H2 The King's Plan",
        'H3 The Joke Tax',
        "H3 Jokester's Revolt",
        "H3 The People's Rebellion",
      ],
      'one outline, in order',
    )
    const [lead, plan] = findAll('p')
    assert.strictEqual(getComputedStyle(lead!).fontSize, '20px', 'the lead is text-xl')
    assert.strictEqual(getComputedStyle(lead!).marginTop, '24px', 'mt-6 after the title')

    // The link's text runs into the colon after it, with no space inside the link.
    assert.strictEqual(
      plan!.textContent!.replace(/\s+/g, ' ').trim(),
      'The king thought long and hard, and finally came up with a brilliant plan: he would tax the jokes in the kingdom.',
    )
    const link = find('a')!
    assert.strictEqual(link.textContent, 'a brilliant plan')
    assert.strictEqual(getComputedStyle(link).textDecorationLine, 'underline')
    assert.strictEqual(getComputedStyle(link).fontWeight, '500', 'font-medium')

    assert.strictEqual(getComputedStyle(find('blockquote')!).fontStyle, 'italic')
    assert.dom('ul li').exists({ count: 3 })
    assert.dom('tbody tr').exists({ count: 3 })
    assert.strictEqual(getComputedStyle(find('h2')!).borderBottomWidth, '1px')
    await a11yAudit()
  })
})
