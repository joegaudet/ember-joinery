import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import HeadingCustom from 'docs-app/examples/heading-custom'

module('Example | heading-custom', function (hooks) {
  setupRenderingTest(hooks)

  test('a heading of your own, on getSectionHeadingLevel', async function (assert) {
    await render(<template><HeadingCustom /></template>)
    const [top, inSection] = [
      ...document.querySelectorAll('.heading-custom h1, .heading-custom h2, .heading-custom h3'),
    ]
    assert.dom(top).hasTagName('h1').hasText('hello there')
    assert.dom(inSection).hasTagName('h2', 'one level down, in a section')
    await a11yAudit()
  })
})
