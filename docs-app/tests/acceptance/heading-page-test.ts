import { module, test } from 'qunit'
import { setupApplicationTest } from 'docs-app/tests/helpers'
import { findAll, visit, waitFor } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { HeadingHarness, scrollIntoView } from '@ember-joinery/test-support'

/** The levels of the headings an `<Example>` on the page shows, in order. */
function levelsIn(example: string): number[] {
  return findAll(
    `[data-test-example="${example}"] .example-preview :is(h1, h2, h3, h4, h5, h6)`,
  ).map(heading => Number(heading.localName.slice(1)))
}

/**
 * The Heading page's examples, where a reader sees them: inside the guide's page, whose own
 * headings come first. Their example tests render them on their own, where they start at h1.
 */
module('Acceptance | primitives/heading.md', function (hooks) {
  setupApplicationTest(hooks)

  test('the examples’ headings carry on from the page’s, which keeps its one h1', async function (assert) {
    await visit('/primitives/heading.md')
    await waitFor('[data-test-example="heading-demo"] .example-preview', { timeout: 15000 })
    // The demo renders once it is in view.
    await scrollIntoView('[data-test-example="heading-demo"] .example-preview')

    assert.deepEqual(
      HeadingHarness.findAll().map(heading => heading.level),
      [3, 4, 4, 4, 5, 6, 5],
      'the demo, under Usage’s h2: top, nav, article, link, section, article, footer',
    )
    assert.deepEqual(levelsIn('heading-custom'), [3, 4], 'the custom heading, under its h2')
    assert.strictEqual(findAll('h1').length, 1, 'the page keeps one h1')
    await a11yAudit()
  })
})
