import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, scrollIntoView } from '@ember-joinery/test-support'
import ViewportTagName from 'docs-app/examples/viewport-tag-name'

class TaggedHarness extends Harness {
  static component = 'tagged'

  get placeholder() {
    return this.part('placeholder')
  }

  get content() {
    return this.queryPart('content')
  }
}

module('Example | viewport-tag-name', function (hooks) {
  setupRenderingTest(hooks)

  test('the placeholder is a section, around the content once it is in view', async function (assert) {
    await render(<template><ViewportTagName /></template>)
    const tagged = new TaggedHarness()
    assert.strictEqual(tagged.placeholder.tagName, 'SECTION')
    assert.strictEqual(tagged.placeholder.getAttribute('aria-label'), 'Wrapped content')

    await scrollIntoView(tagged.placeholder)
    assert.true(tagged.placeholder.contains(tagged.content), 'the content, inside the section')
    assert.true(tagged.content!.textContent!.includes('Content wrapped in a section element'))
    await a11yAudit()
  })
})
