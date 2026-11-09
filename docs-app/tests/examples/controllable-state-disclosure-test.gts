import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, findAll, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import ControllableStateDisclosure from 'docs-app/examples/controllable-state-disclosure'

module('Example | controllable-state-disclosure', function (hooks) {
  setupRenderingTest(hooks)

  test('one disclosure keeps its own state, the other its parent’s', async function (assert) {
    await render(<template><ControllableStateDisclosure /></template>)
    const byLabel = (label: string) =>
      findAll('button').find(button => button.textContent!.trim() === label)!
    const uncontrolled = byLabel('Uncontrolled')
    const controlled = byLabel('Controlled')

    assert.dom(uncontrolled).hasAria('expanded', 'true', '@defaultOpen starts it open')
    await click(uncontrolled)
    assert.dom(uncontrolled).hasAria('expanded', 'false', 'it changes itself')

    assert.dom(controlled).hasAria('expanded', 'false')
    await click(controlled)
    assert.dom(controlled).hasAria('expanded', 'true', 'the parent took the change')
    assert.dom('output').hasText('open')

    await click(byLabel('Close it from outside'))
    assert.dom(controlled).hasAria('expanded', 'false', 'and the parent can close it')
    await a11yAudit()
  })
})
