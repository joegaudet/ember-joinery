import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import IdLabel from 'docs-app/examples/id-label'

module('Example | id-label', function (hooks) {
  setupRenderingTest(hooks)

  test('the ids tie the label and the hint to the input', async function (assert) {
    await render(<template><IdLabel /></template>)
    const email = find('input')!
    assert.dom('label').hasAttribute('for', email.id)
    assert.dom(`#${email.getAttribute('aria-describedby')}`).hasText('We never share it.')
    assert.notStrictEqual(email.id, email.getAttribute('aria-describedby'), 'two different ids')
    await a11yAudit()
  })
})
