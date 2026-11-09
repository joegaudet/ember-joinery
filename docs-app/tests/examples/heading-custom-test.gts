import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import HeadingCustom from 'docs-app/examples/heading-custom'

/** The example, in a root of the test's own: its headings, as the page's outline has them. */
class OutlineHarness extends Harness {
  static override component = 'outline'

  /** Each heading inside, in order: its level (`<h2>` is 2) and its text. */
  get headings(): { level: number; text: string }[] {
    return [...this.element.querySelectorAll('h1, h2, h3, h4, h5, h6')].map(heading => ({
      level: Number(heading.localName.slice(1)),
      text: heading.textContent!.trim(),
    }))
  }
}

module('Example | heading-custom', function (hooks) {
  setupRenderingTest(hooks)

  test('a heading of your own, on getSectionHeadingLevel', async function (assert) {
    await render(
      <template>
        <div data-test-jn="outline"><HeadingCustom /></div>
      </template>,
    )
    assert.deepEqual(new OutlineHarness().headings, [
      { level: 1, text: 'hello there' },
      { level: 2, text: 'hello there' }, // one level down, in a section
    ])
    await a11yAudit()
  })
})
