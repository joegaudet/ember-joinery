import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import Component from '@glimmer/component'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { idFor } from '@ember-joinery/primitives/id'

/** A field that names its parts from its own id, as Joinery's components do. */
class Field extends Component<{ Args: { label: string; hint: string } }> {
  get inputId() {
    return idFor(this, 'input')
  }

  <template>
    {{! idFor works as a helper too }}
    <label for={{this.inputId}}>{{@label}}</label>
    <input id={{this.inputId}} type="email" aria-describedby={{idFor this "hint"}} />
    <p id={{idFor this "hint"}}>{{@hint}}</p>
  </template>
}

module('Integration | primitives | id', function (hooks) {
  setupRenderingTest(hooks)

  test('idFor is stable for an object, and derives part ids from it', async function (assert) {
    const dialog = {}
    const other = {}
    const root = idFor(dialog)
    assert.true(/^jn-\d+$/.test(root), `${root} is a jn- id`)
    assert.strictEqual(idFor(dialog), root, 'the same object always gets the same id')
    assert.notStrictEqual(idFor(other), root, 'another object gets another')
    assert.strictEqual(idFor(dialog, 'content'), `${root}-content`)
    assert.strictEqual(idFor(dialog, 'title'), `${root}-title`)
    await a11yAudit()
  })

  test('in a template, it ties a component’s parts together', async function (assert) {
    await render(
      <template>
        <Field @label="Email" @hint="We never share it." />
        <Field @label="Backup email" @hint="For account recovery." />
      </template>,
    )
    const input = find('input')!
    assert.true(input.id.endsWith('-input'))
    assert.dom('label').hasAttribute('for', input.id)
    assert.dom(`#${input.getAttribute('aria-describedby')}`).hasText('We never share it.')
    const second = document.querySelectorAll('input')[1]!
    assert.notStrictEqual(second.id, input.id, 'each instance has its own')
    await a11yAudit()
  })
})
